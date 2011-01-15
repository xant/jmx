//
//  JMXScript.m
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Foundation/NSFileManager.h>
#import "JMXScript.h"
#import "JMXContext.h"
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#define __JMXV8__ 1
#import "JMXOpenGLScreen.h"
#import "JMXQtVideoCaptureEntity.h"
#import "JMXQtMovieEntity.h"
#import "JMXVideoMixer.h"
#import "JMXAudioFileEntity.h"
#import "JMXCoreAudioOutput.h"
#import "JMXQtAudioCaptureEntity.h"
#import "JMXCoreImageFilter.h"
#import "JMXAudioSpectrumAnalyzer.h"
#import "JMXInputPin.h"
#import "JMXOutputPin.h"
#import "JMXDrawEntity.h"
#import "JMXPoint.h"
#import "JMXColor.h"
#import "JMXSize.h"
#import "JMXElement.h"
#import "JMXCDATA.h"
#import "JMXAttribute.h"
#import "JMXGraph.h"
#import "NSXMLNode+V8.h"

@class JMXEntity;

using namespace v8;
using namespace std;

/*
typedef std::map<id, v8::Persistent<v8::Object> > InstMap;
*/

typedef std::pair< JMXScript *, Persistent<Context> >CtxPair;
typedef std::map< JMXScript *, Persistent<Context> > CtxMap;

CtxMap contextes;

typedef struct __JMXPersistantInstance {
    id obj;
    v8::Persistent<Object> jsObj;
} JMXPersistentInstance;

typedef struct __JMXV8ClassDescriptor {
    const char *className;
    const char *jsClassName;
    v8::Handle<Value> (*jsConstructor)(const Arguments& args);
} JMXV8ClassDescriptor;

static JMXV8ClassDescriptor mappedClasses[] = {
    { "JMXEntity",                "Entity",          JMXEntityJSConstructor },
    { "JMXOpenGLScreen",          "OpenGLScreen",    JMXOpenGLScreenJSConstructor },
    { "JMXQtVideoCaptureEntity",  "QtVideoCapture",  JMXQtVideoCaptureEntityJSConstructor },
    { "JMXQtMovieEntity",         "QtMovieFile",     JMXQtMovieEntityJSConstructor },
    { "JMXCoreImageFilter",       "CoreImageFilter", JMXCoreImageFilterJSConstructor },
    { "JMXVideoMixer",            "VideoMixer",      JMXVideoMixerJSConstructor },
    { "JMXAudioFileEntity",       "CoreAudioFile",   JMXAudioFileEntityJSConstructor },
    { "JMXCoreAudioOutput",       "CoreAudioOutput", JMXCoreAudioOutputJSConstructor },
    { "JMXQtAudioCaptureEntity",  "QtAudioCapture",  JMXQtAudioCaptureEntityJSConstructor },
    { "JMXAudioSpectrumAnalyzer", "AudioSpectrum",   JMXAudioSpectrumAnalyzerJSConstructor },
    { "JMXDrawEntity",            "DrawPath",        JMXDrawEntityJSConstructor },
    { "JMXPoint",                 "Point",           JMXPointJSConstructor },
    { "JMXColor",                 "Color",           JMXColorJSConstructor },
    { "JMXSize",                  "Size",            JMXSizeJSConstructor },
    { "NSXMLNode",                "Node",            NSXMLNodeJSConstructor },
    { "JMXElement",               "Element",         JMXElementJSConstructor },
    { "JMXCDATA",                 "CDATA",           JMXCDATAJSConstructor },
    { "JMXAttribute",             "Attribute"   ,    JMXAttributeJSConstructor },
    
    { NULL,                       NULL,              NULL }
};

// Extracts a C string from a V8 Utf8Value.
static const char* ToCString(const v8::String::Utf8Value& value) {
    return *value ? *value : "<string conversion failed>";
}

static v8::Handle<Value> ExportPin(const Arguments& args) {
    if (args.Length() < 1) return Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Object> pinObj = args[0]->ToObject();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::String::Utf8Value proto(pinObj->ToString());
    NSString *objectType = [NSString stringWithUTF8String:*proto];
    if ([objectType isEqualToString:@"[object Pin]"]) {
        v8::Handle<v8::Value> fArgs[args.Length()-1];
        for (int i = 0; i < args.Length()-1; i++)
            fArgs[i] = args[i+1];
        v8::Handle<Function> exportFunction = v8::Local<v8::Function>::Cast(pinObj->Get(String::New("export")));
        // call the 'export()' proptotype method exposed by Pin objects
        return scope.Close(exportFunction->Call(pinObj, args.Length()-1, fArgs));
    } else {
        NSLog(@"(exportPin) Bad argument: %@", objectType);
    }
    [pool drain];
    return scope.Close(v8::Boolean::New(0));
}

static void ReportException(v8::TryCatch* try_catch) {
    //v8::Locker lock;
    v8::HandleScope handle_scope;
    v8::String::Utf8Value exception(try_catch->Exception());
    const char* exception_string = ToCString(exception);
    v8::Handle<v8::Message> message = try_catch->Message();
    if (message.IsEmpty()) {
        // V8 didn't provide any extra information about this error; just
        // print the exception.
        printf("%s\n", exception_string);
    } else {
        // Print (filename):(line number): (message).
        v8::String::Utf8Value filename(message->GetScriptResourceName());
        const char* filename_string = ToCString(filename);
        int linenum = message->GetLineNumber();
        printf("%s:%i: %s\n", filename_string, linenum, exception_string);
        // Print line of source code.
        v8::String::Utf8Value sourceline(message->GetSourceLine());
        const char* sourceline_string = ToCString(sourceline);
        printf("%s\n", sourceline_string);
        // Print wavy underline (GetUnderline is deprecated).
        int start = message->GetStartColumn();
        for (int i = 0; i < start; i++) {
            printf(" ");
        }   
        int end = message->GetEndColumn();
        for (int i = start; i < end; i++) {
            printf("^");
        }   
        printf("\n");
        v8::String::Utf8Value stack_trace(try_catch->StackTrace());
        if (stack_trace.length() > 0) {
            const char* stack_trace_string = ToCString(stack_trace);
            printf("%s\n", stack_trace_string);
        }  
    }
}

static v8::Handle<Value> IsDir(const Arguments& args) {
    if (args.Length() < 1) return Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSDictionary *content = [[NSFileManager defaultManager] attributesOfItemAtPath:[NSString stringWithUTF8String:*value] error:nil];
    if (content) {
        if ([content objectForKey:NSFileType] == NSFileTypeDirectory) {
            [pool drain];
            return scope.Close(v8::Boolean::New(1));
        }
    }
    [pool drain];
    return scope.Close(v8::Boolean::New(0));
}

static v8::Handle<Value> ListDir(const Arguments& args) {
    if (args.Length() < 1) return Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[NSString stringWithUTF8String:*value] error:nil];
    if (content) {
        v8::Handle<Array> list = Array::New([content count]);
        int cnt = 0;
        for (NSString *path in content) {
            list->Set(cnt++, String::New([path UTF8String]));
        }
        [pool drain];
        return scope.Close(list);
    }
    [pool drain];
    return Undefined();
}

static v8::Handle<Value> Rand(const Arguments& args) {
    //v8::Locker lock;
    HandleScope scope;
    return scope.Close(v8::Integer::New(rand()));
}

static v8::Handle<Value> Echo(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    {
        v8::Unlocker unlocker;
        NSLog(@"%s", *value);
    }
    return v8::Undefined();
}

static v8::Handle<Value> DumpDOM(const Arguments& args) {
    //v8::Locker lock;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    HandleScope scope;
    NSString *xmlString = [[JMXContext sharedContext] dumpDOM];
    v8::Handle<String> output = String::New([xmlString UTF8String]);
    [pool release];
    return scope.Close(output);
}

static v8::Handle<Value> ExecJSCode(const char *code, uint32_t length, const char *name)
{
    HandleScope scope;
    v8::Handle<v8::Value> result;
    v8::TryCatch try_catch;
    v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New(code, length), String::New(name));
    if (!compiledScript.IsEmpty()) {
        result = compiledScript->Run();
        if (result.IsEmpty()) {
            ReportException(&try_catch);
        } else if (!result->IsUndefined()) {
            // Convert the result to an ASCII string and print it.
            //String::AsciiValue ascii(result);
            //NSLog(@"%s\n", *ascii);
        }
    } else {
        ReportException(&try_catch);
    }
    return scope.Close(result);
}

static v8::Handle<Value> Include(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *path = [NSString stringWithUTF8String:*value];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fh) {
        // try searching in the main core directory
        NSBundle *mainBundle = [NSBundle mainBundle];
        path = [NSString stringWithFormat:@"%@/js/%s", [mainBundle builtInPlugInsPath], *value];
        fh = [NSFileHandle fileHandleForReadingAtPath:path];
        if (!fh) {
            // if still not found, let's try in the user include directory
            path = [NSString stringWithFormat:@"~/Library/JMX/js/%s", [mainBundle builtInPlugInsPath], *value];
        }
    }
    if (fh) {
        NSData *data = [fh readDataToEndOfFile];
        ExecJSCode((const char *)[data bytes], [data length], [path UTF8String]);
    }
    [pool release];
    return v8::Undefined();
}

static v8::Handle<Value> ListEntities(const Arguments& args)
{
    //v8::Locker lock;

    NSString *output = [NSString string];
    NSArray *entities;
    {
        entities = [[JMXContext sharedContext] allEntities];
    }
    if (entities == NULL) {
        v8::Handle<Primitive> t = Undefined();
        return reinterpret_cast<v8::Handle<String>&>(t);
    }
   
    for (JMXEntity *entity in entities) {
        output = [output stringByAppendingFormat:@"%@\n", [entity description]];
    }
    NSLog(@"%@", output);

    return String::New([output UTF8String]);
    
}

static v8::Handle<Value> Sleep(const Arguments& args)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    if (args.Length() >= 1) {// XXX - ignore extra parameters
        v8::Unlocker unlocker;
        [NSThread sleepForTimeInterval:args[0]->NumberValue()];
    }
    return Undefined();
}

static v8::Handle<Value> Run(const Arguments& args)
{   
    HandleScope handleScope;
    v8::Locker locker;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    //v8::Locker::StopPreemption();
    //globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    if (args.Length() >= 1 && args[0]->IsFunction()) {
        //v8::Locker::StartPreemption(50);
        while (1) {
            HandleScope iterationScope;
            if (globalObject->GetHiddenValue(String::New("quit"))->BooleanValue())
                break;
            v8::Local<v8::Function> foo =
            v8::Local<v8::Function>::Cast(args[0]);
            v8::Handle<v8::Value> fArgs[args.Length()-1];
            for (int i = 0; i < args.Length()-1; i++)
                fArgs[i] = args[i+1];
            //v8::Local<v8::Value> result = foo->Call(foo, args.Length()-1, fArgs);
            foo->Call(foo, args.Length()-1, fArgs);
        }
        // restore quit status for nested loops
        //v8::Locker::StopPreemption();
        if (globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(0)));
    }
    //v8::Locker::StartPreemption(50);
    v8::Handle<Primitive> t = Undefined();
    return reinterpret_cast<v8::Handle<String>&>(t);
}

static v8::Handle<Value> Quit(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    Local<Context> globalContext = v8::Context::GetCurrent();
    Local<Object> globalObject  = globalContext->Global();
    globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(1));
    return Undefined();
}

static v8::Handle<Value> GetDocument(v8::Local<v8::String> name, const v8::AccessorInfo& info)
{
    HandleScope handleScope;
    return handleScope.Close([[[JMXContext sharedContext] dom] jsObj]);
}

@interface DispatchArg : NSObject
{
    NSString *source;
    JMXEntity *entity;
}
@property (retain) NSString *source;
@property (retain) JMXEntity *entity;
@end
@implementation DispatchArg
@synthesize source, entity;
@end

@implementation JMXScript

@synthesize scriptEntity;

+ (void)runScript:(NSString *)source
{
    return [self runScript:source withEntity:nil];
}

+ (void)runScript:(NSString *)source withEntity:(JMXEntity *)entity
{
    JMXScript *jsContext = [[self alloc] init];
    [jsContext runScript:source withEntity:entity];
    [jsContext release];
}

+ (void)dispatchScript:(DispatchArg *)arg
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self runScript:arg.source withEntity:arg.entity];
    [pool drain];
}

// TODO - use a NSOperationQueue
+ (void)runScriptInBackground:(NSString *)source withEntity:(JMXEntity *)entity {
    DispatchArg *arg = [[DispatchArg alloc] init];
    arg.source = source;
    arg.entity = entity;
    //[self performSelector:@selector(dispatchScript:) onThread:[JMXContext scriptThread] withObject:arg waitUntilDone:NO];
    [self performSelectorInBackground:@selector(dispatchScript:) withObject:arg];
    [arg release];
}

+ (void)runScriptInBackground:(NSString *)source {
    //[self performSelector:@selector(runScript:) onThread:[JMXContext scriptThread] withObject:source waitUntilDone:NO];
    [self performSelectorInBackground:@selector(dispatchScript:) withObject:source];
}

- (void)registerClasses:(v8::Handle<ObjectTemplate>)ctxTemplate;
{
    // register all the core entities exposed to the javascript context.
    // JMXPins are also exposed but those can't be created directly from
    // javascript but must be obtained through the methods provided by the JMXEntity class.
    // So there is no constructor/destructor to be registered for not-entity classes.
    // Note that all entity-related constructors (as well as distructors) are defined through the 
    // JMXV8_EXPORT_ENTITY_CLASS() macro (declared in JMXEntity.h)
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (int i = 0; mappedClasses[i].className != NULL; i++) {
        v8::Handle<FunctionTemplate> constructor = FunctionTemplate::New(mappedClasses[i].jsConstructor);
        Class entityClass = NSClassFromString([NSString stringWithUTF8String:mappedClasses[i].className]);
        [entityClass jsRegisterClassMethods:constructor];
        ctxTemplate->Set(String::New(mappedClasses[i].jsClassName), constructor);
    }
    [pool drain];
}

- (id)init
{
    self = [super init];
    if (self) {
        persistentInstances = [[NSMutableDictionary alloc] init];
        v8::Locker locker;
        HandleScope handle_scope;
        Local<ObjectTemplate>ctxTemplate = ObjectTemplate::New();

        ctxTemplate->Set(String::New("rand"), FunctionTemplate::New(Rand));
        ctxTemplate->Set(String::New("echo"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("print"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("include"), FunctionTemplate::New(Include));
        ctxTemplate->Set(String::New("sleep"), FunctionTemplate::New(Sleep));
        ctxTemplate->Set(String::New("lsdir"), FunctionTemplate::New(ListDir));
        ctxTemplate->Set(String::New("isdir"), FunctionTemplate::New(IsDir));
        ctxTemplate->Set(String::New("exportPin"), FunctionTemplate::New(ExportPin));
        ctxTemplate->Set(String::New("dumpDOM"), FunctionTemplate::New(DumpDOM));
        ctxTemplate->Set(String::New("run"), FunctionTemplate::New(Run));
        ctxTemplate->Set(String::New("quit"), FunctionTemplate::New(Quit));

        ctxTemplate->SetInternalFieldCount(1);
        
        /* TODO - think if worth exposing such global functions
        ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
        ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        */
        [self registerClasses:ctxTemplate];
        ctx = Persistent<Context>::New(Context::New(NULL, ctxTemplate));
        // Create a new execution environment containing the built-in
        // functions
        contextes[self] = ctx;
        scriptEntity = nil;
        v8::Context::Scope context_scope(ctx);
        ctx->Global()->SetAccessor(String::New("document"), GetDocument);
        char baseInclude[] = "include('JMX.js');";
        // Enter the newly created execution environment.
        ExecJSCode(baseInclude, strlen(baseInclude), "JMX");
    }
    return self;
}

- (void)clearPersistentInstances
{
    NSArray *objs = [persistentInstances allKeys];
    for (id obj in objs)
        [self removePersistentInstance:obj];
}

- (void)dealloc
{
    if (scriptEntity && [scriptEntity conformsToProtocol:@protocol(JMXRunLoop)])
        [scriptEntity performSelector:@selector(stop)];
    [self clearPersistentInstances];
    while( V8::IdleNotification() )
        ;
    contextes.erase(self);
    ctx.Dispose();
    [persistentInstances release];
    [super dealloc];
}

- (void)execCode:(NSString *)code
{
}

- (void)runScript:(NSString *)source
{
    return [self runScript:source withEntity:nil];
}

- (void)runScript:(NSString *)script withEntity:(JMXEntity *)entity
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Locker locker;
    v8::HandleScope handle_scope;
   
    v8::Context::Scope context_scope(ctx);
    if (entity) {
        scriptEntity = entity;
        //ctx->Global()->SetPointerInInternalField(0, scriptEntity);
    }
    //NSLog(@"%@", [self exportGraph:[[JMXContext sharedContext] allEntities] andPins:nil]);
    ctx->Global()->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    ExecJSCode([script UTF8String], [script length],
             entity ? [entity.label UTF8String] : [[NSString stringWithFormat:@"%@", self] UTF8String]);
    [pool drain];
}

+ (JMXScript *)getContext:(Local<Context>&)currentContext
{
    JMXScript *context;
    CtxMap::const_iterator end = contextes.end(); 
    for (CtxMap::const_iterator it = contextes.begin(); it != end; ++it)
    {
        if (currentContext == it->second) {
            context = it->first;
        }
    }
    return context;
}

- (void)addPersistentInstance:(Persistent<Object>)persistent obj:(id)obj
{
    JMXPersistentInstance *instance = (JMXPersistentInstance *)malloc(sizeof(JMXPersistentInstance));
    instance->obj = [obj retain];
    instance->jsObj = persistent;
    NSValue *val = [NSValue valueWithPointer:instance];
    [persistentInstances setObject:val forKey:[obj hashString]];
}

- (void)removePersistentInstance:(id)obj
{
    JMXPersistentInstance *p = nil;
    id key;
    if ([obj respondsToSelector:@selector(hashString)])
        key = [obj hashString];
    else
        key = obj;
    p = (JMXPersistentInstance *)[[persistentInstances objectForKey:key] pointerValue];
    NSLog(@"Releasing Persistent Instance: %@ (%d)", p->obj, [p->obj retainCount]);
    if (p) {
        if ([p->obj conformsToProtocol:@protocol(JMXRunLoop)])
            [p->obj performSelector:@selector(stop)];
        [p->obj release];
        if (!p->jsObj.IsEmpty()) {
            p->jsObj.ClearWeak();
            p->jsObj.Dispose();
            p->jsObj.Clear();
        }
        [persistentInstances removeObjectForKey:key];
    }
}

- (NSString *)exportGraph:(NSArray *)entities andPins:(NSArray *)pins
{
    NSString *output = [[[NSString alloc] init] autorelease];
    NSMutableDictionary *entityNames = [[NSMutableDictionary alloc] init];
    for (JMXEntity *entity in entities) {
        NSString *entityName = [NSString stringWithFormat:@"%@", entity.label];
        NSString *numberedName = entityName;
        int cnt = 1;
        while ([entityNames objectForKey:numberedName]) {
            numberedName = [entityName stringByAppendingFormat:@"%d", cnt++];
        }
        for (int n = 0; mappedClasses[n].className; n++) {
            if (strcmp(mappedClasses[n].className, [[entity className] UTF8String]) == 0) {
                output = [output stringByAppendingFormat:@"%@ = new %s();\n", numberedName, mappedClasses[n].jsClassName];
                [entityNames setObject:numberedName forKey:entity];
                break;
            }
        }
    }
    
    for (JMXEntity *entity in [entityNames allKeys]) {
        for (NSString *pinLabel in [entity outputPins]) {
            JMXOutputPin *pin = [entity outputPinWithLabel:pinLabel];
            if (pin.connected) {
                for (id receiver in [pin receivers]) {
                    if ([receiver isKindOfClass:[JMXPin class]]) {
                        id receiverObj = ((JMXPin *)receiver).owner;
                        if ([receiverObj isKindOfClass:[JMXEntity class]]) {
                            JMXEntity *receiverEntity = (JMXEntity *)receiverObj;
                            output = [output stringByAppendingFormat:@"%@.outputPin('%@').connect(%@.inputPin('%@'));\n",
                                      [entityNames objectForKey:entity], pin.label, [entityNames objectForKey:receiverEntity], 
                                      ((JMXPin *)receiver).label];
                        }
                    } else {
                        // TODO - Error Messages
                    }
                }
            }
        }
    }
    if (pins) {
        for (id value in pins) {
            if ([value isKindOfClass:[JMXPin class]]) {
                JMXPin *pin = (JMXPin *)value;
                JMXEntity *owner = pin.owner;
                if (pin.direction == kJMXOutputPin) {
                    output = [output stringByAppendingFormat:@"%@.outputPin('%@').export();",
                              [entityNames objectForKey:owner], pin.label];
                } else {
                    output = [output stringByAppendingFormat:@"%@.inputPin('%@').export();",
                              [entityNames objectForKey:owner], pin.label];
                }
            }
        }
    }
    return output;
}

@end
