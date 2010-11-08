//
//  VJXJavaScript.m
//  VeeJay
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Foundation/NSFileManager.h>
#import "VJXJavaScript.h"
#import "VJXContext.h"
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#define __VJXV8__ 1
#import "VJXOpenGLScreen.h"
#import "VJXQtVideoCaptureEntity.h"
#import "VJXQtMovieEntity.h"
#import "VJXVideoMixer.h"
#import "VJXAudioFileEntity.h"
#import "VJXCoreAudioOutput.h"
#import "VJXCoreImageFilter.h"
#import "VJXAudioSpectrumAnalyzer.h"
#import "VJXInputPin.h"
#import "VJXOutputPin.h"

@class VJXEntity;

using namespace v8;
using namespace std;

typedef std::map<id, v8::Persistent<v8::Object> > InstMap;
typedef std::pair< VJXJavaScript *, Persistent<Context> >CtxPair;
typedef std::map< VJXJavaScript *, Persistent<Context> > CtxMap;
CtxMap contextes;

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
        return exportFunction->Call(pinObj, args.Length()-1, fArgs);
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
            return v8::Boolean::New(1);
        }
    }
    [pool drain];
    return v8::Boolean::New(0);
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

static v8::Handle<Value> Include(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
    //v8::Locker lock;
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *path = [NSString stringWithUTF8String:*value];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fh) {
        NSData *data = [fh readDataToEndOfFile];
        v8::TryCatch try_catch;
        v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New((const char *)[data bytes], [data length]), String::New([path UTF8String]));
        if (!compiledScript.IsEmpty()) {
            compiledScript->Run();
        } else {
            ReportException(&try_catch);
        }
        
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
        entities = [[VJXContext sharedContext] allEntities];
    }
    if (entities == NULL) {
        v8::Handle<Primitive> t = Undefined();
        return reinterpret_cast<v8::Handle<String>&>(t);
    }
   
    for (VJXEntity *entity in entities) {
        output = [output stringByAppendingFormat:@"%@\n", [entity description]];
    }
    NSLog(@"%@", output);

    return String::New([output UTF8String]);
    
}

static v8::Handle<Value> Sleep(const Arguments& args)
{   
    //v8::Locker lock;

    if (args.Length() >= 1) {// XXX - ignore extra parameters
        v8::Unlocker unlocker;
        [NSThread sleepForTimeInterval:args[0]->NumberValue()];
    }
    return Undefined();
}

static v8::Handle<Value> Run(const Arguments& args)
{   
    //v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCurrent();
    Local<Object> globalObject  = context->Global();
    //v8::Locker::StopPreemption();
    if (globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(0)));
    if (args.Length() >= 1 && args[0]->IsFunction()) {
        //v8::Locker::StartPreemption(50);
        while (1) {
            if (globalObject->GetHiddenValue(String::New("quit"))->BooleanValue())
                break;
            v8::Local<v8::Function> foo =
            v8::Local<v8::Function>::Cast(args[0]);
            v8::Handle<v8::Value> fArgs[args.Length()-1];
            for (int i = 0; i < args.Length()-1; i++)
                fArgs[i] = args[i+1];
            v8::Local<v8::Value> result = foo->Call(foo, args.Length()-1, fArgs);
            //usleep(10);
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

@interface DispatchArg : NSObject
{
    NSString *source;
    VJXEntity *entity;
}
@property (retain) NSString *source;
@property (retain) VJXEntity *entity;
@end
@implementation DispatchArg
@synthesize source, entity;
@end

@implementation VJXJavaScript

+ (void)runScript:(NSString *)source
{
    return [self runScript:source withEntity:nil];
}

+ (void)runScript:(NSString *)source withEntity:(VJXEntity *)entity
{
    VJXJavaScript *jsContext = [[self alloc] init];
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
+ (void)runScriptInBackground:(NSString *)source withEntity:(VJXEntity *)entity {
    DispatchArg *arg = [[DispatchArg alloc] init];
    arg.source = source;
    arg.entity = entity;
    //[self performSelector:@selector(dispatchScript:) onThread:[VJXContext scriptThread] withObject:arg waitUntilDone:NO];
    [self performSelectorInBackground:@selector(dispatchScript:) withObject:arg];
    [arg release];
}

+ (void)runScriptInBackground:(NSString *)source {
    //[self performSelector:@selector(runScript:) onThread:[VJXContext scriptThread] withObject:source waitUntilDone:NO];
    [self performSelectorInBackground:@selector(dispatchScript:) withObject:source];
}

- (void)registerClasses:(v8::Handle<ObjectTemplate>)ctxTemplate;
{
    // register all the core entities exposed to the javascript context.
    // VJXPins are also exposed but those can't be created directly from
    // javascript but must be obtained through the methods provided by the VJXEntity class.
    // So there is no constructor/destructor to be registered for not-entity classes.
    // Note that all entity-related constructors (as well as distructors) are defined through the 
    // VJXV8_EXPORT_ENTITY_CLASS() macro (declared in VJXEntity.h)
    ctxTemplate->Set(String::New("VideoOutput"), FunctionTemplate::New(VJXOpenGLScreenJSConstructor));
    ctxTemplate->Set(String::New("VideoCapture"), FunctionTemplate::New(VJXQtVideoCaptureEntityJSConstructor));
    ctxTemplate->Set(String::New("Movie"), FunctionTemplate::New(VJXQtMovieEntityJSConstructor));
    ctxTemplate->Set(String::New("VideoMixer"), FunctionTemplate::New(VJXVideoMixerJSConstructor));
    ctxTemplate->Set(String::New("VideoFilter"), FunctionTemplate::New(VJXCoreImageFilterJSConstructor));
    ctxTemplate->Set(String::New("AudioFile"), FunctionTemplate::New(VJXAudioFileEntityJSConstructor));
    ctxTemplate->Set(String::New("AudioOutput"), FunctionTemplate::New(VJXCoreAudioOutputJSConstructor));
    ctxTemplate->Set(String::New("AudioSpectrum"), FunctionTemplate::New(VJXAudioSpectrumAnalyzerJSConstructor));
}

- (id)init
{
    self = [super init];
    if (self) {
        v8::Locker locker;
        HandleScope handle_scope;
        Local<ObjectTemplate>ctxTemplate = ObjectTemplate::New();

        ctxTemplate->Set(String::New("echo"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("print"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("include"), FunctionTemplate::New(Include));
        ctxTemplate->Set(String::New("sleep"), FunctionTemplate::New(Sleep));
        ctxTemplate->Set(String::New("lsdir"), FunctionTemplate::New(ListDir));
        ctxTemplate->Set(String::New("isdir"), FunctionTemplate::New(IsDir));
        ctxTemplate->Set(String::New("exportPin"), FunctionTemplate::New(ExportPin));
        ctxTemplate->Set(String::New("run"), FunctionTemplate::New(Run));
        ctxTemplate->Set(String::New("quit"), FunctionTemplate::New(Quit));


        /* TODO - think if worth exposing such global functions
        ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
        ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        */
        [self registerClasses:ctxTemplate];
        ctx = Context::New(NULL, ctxTemplate);

        // Create a new execution environment containing the built-in
        // functions
        contextes[self] = ctx;
        scriptEntity = nil;
        // Enter the newly created execution environment.
    }
    return self;
}

- (void)clearPersistentInstances
{
    InstMap::const_iterator end = instancesMap.end(); 
    for (InstMap::const_iterator it = instancesMap.begin(); it != end; ++it)
    {
        Persistent<Object> obj = it->second;
        if ([it->first conformsToProtocol:@protocol(VJXRunLoop)])
            [it->first performSelector:@selector(stop)];
        [it->first release];
        instancesMap.erase(it->first);
        obj.Dispose();
        obj.Clear();
    }
}

- (void)dealloc
{
    [self clearPersistentInstances];
    ctx.Dispose();
    while( V8::IdleNotification() )
        ;
    contextes.erase(self);
    if (scriptEntity && [scriptEntity conformsToProtocol:@protocol(VJXRunLoop)])
            [scriptEntity performSelector:@selector(stop)];
    [super dealloc];
}

- (void)runScript:(NSString *)source
{
    return [self runScript:source withEntity:nil];
}

- (void)runScript:(NSString *)script withEntity:(VJXEntity *)entity
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Locker locker;
    v8::HandleScope handle_scope;
   
    v8::Context::Scope context_scope(ctx);
    if (entity) {
        scriptEntity = entity;
        ctx->Global()->SetPointerInInternalField(0, scriptEntity);
    }
    //ctx->Global()->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    v8::TryCatch try_catch;

    v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New([script UTF8String]), String::New("VJXScript"));
    if (!compiledScript.IsEmpty()) {
        //v8::Locker::StartPreemption(50);
        compiledScript->Run();
    } else {
        ReportException(&try_catch);
    }
    [pool drain];
}

+ (VJXJavaScript *)getContext:(Local<Context>&)currentContext
{
    VJXJavaScript *context;
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
    instancesMap[obj] = persistent; 
}

- (void)removePersistentInstance:(id)obj
{
    Persistent<Object>p = instancesMap[obj];
    instancesMap.erase(obj);
    if (!p.IsEmpty()) {
        p.Dispose();
        p.Clear();
    }
    if ([obj conformsToProtocol:@protocol(VJXRunLoop)])
        [obj performSelector:@selector(stop)];
    [obj release];
}

@end

#pragma mark Accessor-Wrappers 

v8::Handle<v8::Value>GetNumberProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<v8::Value>GetStringProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<Value>GetObjectProperty(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value value(name);
    NSString *property = [NSString stringWithUTF8String:*value];
    SEL selector = NSSelectorFromString(property);
    if (obj && [obj respondsToSelector:selector]) {
        id output = [obj performSelector:selector];
        if ([output isKindOfClass:[NSString class]]) {
            [pool drain];
            return handle_scope.Close(String::New([(NSString *)output UTF8String], [(NSString *)output length]));
        } else if ([output isKindOfClass:[NSNumber class]]) {
            [pool drain];
            return handle_scope.Close(Number::New([(NSNumber *)output doubleValue]));
        } else if ([output isKindOfClass:[VJXPin class]]) {
            // TODO - wrap
        } else if ([output isKindOfClass:[VJXEntity class]]) {
            // TODO - wrap
        } else {
            // unsupported class
        }
    }
    else 
        NSLog(@"Unknown property %@", property);
    [pool drain];
    return Undefined();
    
}

v8::Handle<Value>GetBoolProperty(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    BOOL ret = NO;
    String::Utf8Value value(name);
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*value];
        SEL selector = NSSelectorFromString(property);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown property %@", property);
            [pool drain];
            return Undefined();
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [invocation getReturnValue:&ret];
        [pool drain];
    }
    return handle_scope.Close(v8::Boolean::New(ret));
}

v8::Handle<Value>GetIntProperty(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    int32_t ret = 0;
    String::Utf8Value value(name);

    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*value];
        SEL selector = NSSelectorFromString(property);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown property %@", property);
            [pool drain];
            return Undefined();
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [invocation getReturnValue:&ret];
        [pool drain];
    }
    return handle_scope.Close(v8::Integer::New(ret));
}

void SetStringProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsString()) {
        NSLog(@"Bad parameter (not string) passed to %s", *nameStr);
        return;
    }
    String::Utf8Value str(value->ToString());
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                            [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                                                               [property substringFromIndex:1]]
                            ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSString *newValue = [NSString stringWithUTF8String:*str];
        [obj performSelector:selector withObject:newValue];
        [pool release];
    }
}

void SetNumberProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsNumber()) {
        NSLog(@"Bad parameter (not number) passed to %s", *nameStr);
        return;
    }
    double number = value->NumberValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                             [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                              [property substringFromIndex:1]]
                             ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSNumber *newValue = [NSNumber numberWithDouble:number];
        [obj performSelector:selector withObject:newValue];
        [pool release];
    }
}

void SetBoolProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!(value->IsBoolean() || value->IsNumber())) {
        NSLog(@"Bad parameter (not bool) passed to %s", *nameStr);
        return;
    }
    BOOL newValue = value->BooleanValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                             [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                              [property substringFromIndex:1]]
                             ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setArgument:&newValue atIndex:0];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [pool release];
    }
}

void SetIntProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsInt32()) {
        NSLog(@"Bad parameter (not int32) passed to %s", *nameStr);
        return;
    }
    int32_t newValue = value->NumberValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        v8::Unlocker unlocker;

        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                             [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                              [property substringFromIndex:1]]
                             ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setArgument:&newValue atIndex:0];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [pool release];
    }
}
