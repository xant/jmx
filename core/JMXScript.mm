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
#import "JMXImageData.h"
#import "NSColor+V8.h"
#import "JMXSize.h"
#import "JMXElement.h"
#import "JMXCDATA.h"
#import "JMXAttribute.h"
#import "JMXGraph.h"
#import "JMXGraphFragment.h"
#import "NSXMLNode+V8.h"
#import "JMXScriptTimer.h"
#import "JMXScriptEntity.h"
#import "JMXEvent.h"
#import "JMXEventListener.h"
#import "JMXCanvasElement.h"
#import "JMXImageEntity.h"
#import "JMXPhidgetEncoderEntity.h"
#import "JMXTextEntity.h"
#import "JMXScriptInputPin.h"
#import "JMXScriptOutputPin.h"
#import "JMXHIDInputEntity.h"
#import "node.h"
#import "NSDictionary+V8.h"
#import "v8_typed_array.h"
#import <QuartzCore/QuartzCore.h>

using namespace v8;
using namespace std;
using namespace node;
/*
typedef std::map<id, v8::Persistent<v8::Object> > InstMap;
*/

typedef std::pair< JMXScript *, Handle<Context> >CtxPair;
typedef std::map< JMXScript *, Handle<Context> > CtxMap;

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
    { "JMXEntity",                "Entity",           JMXEntityJSConstructor                },
    { "JMXOpenGLScreen",          "OpenGLScreen",     JMXOpenGLScreenJSConstructor          },
    { "JMXQtVideoCaptureEntity",  "QtVideoCapture",   JMXQtVideoCaptureEntityJSConstructor  },
    { "JMXQtMovieEntity",         "QtMovieFile",      JMXQtMovieEntityJSConstructor         },
    { "JMXImageEntity",           "ImageFile",        JMXImageEntityJSConstructor           },
    { "JMXCoreImageFilter",       "CoreImageFilter",  JMXCoreImageFilterJSConstructor       },
    { "JMXVideoMixer",            "VideoMixer",       JMXVideoMixerJSConstructor            },
    { "JMXAudioFileEntity",       "CoreAudioFile",    JMXAudioFileEntityJSConstructor       },
    { "JMXCoreAudioOutput",       "CoreAudioOutput",  JMXCoreAudioOutputJSConstructor       },
    { "JMXQtAudioCaptureEntity",  "QtAudioCapture",   JMXQtAudioCaptureEntityJSConstructor  },
    { "JMXAudioSpectrumAnalyzer", "AudioSpectrum",    JMXAudioSpectrumAnalyzerJSConstructor },
    { "JMXDrawEntity",            "DrawPath",         JMXDrawEntityJSConstructor            },
    { "JMXPoint",                 "Point",            JMXPointJSConstructor                 },
    { "NSColor",                  "Color",            JMXColorJSConstructor                 },
    { "JMXSize",                  "Size",             JMXSizeJSConstructor                  },
    { "NSXMLNode",                "Node",             NSXMLNodeJSConstructor                },
    { "JMXElement",               "Element",          JMXElementJSConstructor               },
    { "JMXCDATA",                 "CDATA",            JMXCDATAJSConstructor                 },
    { "JMXAttribute",             "Attribute",        JMXAttributeJSConstructor             },
    { "JMXGraphFragment",         "DocumentFragment", JMXGraphFragmentJSConstructor         },
    { "JMXCanvasElement",         "HTMLCanvasElement",JMXCanvasElementJSConstructor         },
    { "JMXPhidgetEncoderEntity",  "PhidgetEncoder",   JMXPhidgetEncoderEntityJSConstructor  },
    { "JMXScriptInputPin",        "InputPin",         JMXInputPinJSConstructor              },
    { "JMXScriptOutputPin",       "OutputPin",        JMXOutputPinJSConstructor             },
    { "JMXTextEntity",            "TextEntity",       JMXTextEntityJSConstructor            },
    { "JMXHIDInputEntity",        "HIDInput",         JMXHIDInputEntityJSConstructor        },
    { NULL,                       NULL,               NULL                                  }
};

void JSExit(int code)
{
    v8::Locker locker;
    v8::HandleScope handleScope;
    v8::Local<v8::Context> context = v8::Context::GetCalling();
    v8::Local<v8::Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(v8::String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    entity.active = NO;
    [entity resetContext];
}

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
        v8::Handle<Value> ret = Undefined();
        v8::Handle<Function> exportFunction = v8::Local<v8::Function>::Cast(pinObj->Get(String::New("export")));
        int nArgs = args.Length() ? args.Length() - 1 : 0;
        v8::Handle<v8::Value> *fArgs = nArgs
                                     ? (v8::Handle<v8::Value> *)malloc(sizeof(v8::Handle<v8::Value>) * nArgs)
                                     : nil;
        for (int i = 0; nArgs; i++)
            fArgs[i] = args[i+1];
        // call the 'export()' proptotype method exposed by Pin objects
        ret = exportFunction->Call(pinObj, nArgs, fArgs);
        if (fArgs)
            free(fArgs);
        
        return scope.Close(ret);
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
        NSLog(@"%s", exception_string);
    } else {
        // Print (filename):(line number): (message).
        v8::String::Utf8Value filename(message->GetScriptResourceName());
        const char* filename_string = ToCString(filename);
        int linenum = message->GetLineNumber();
        NSLog(@"%s:%i: %s", filename_string, linenum, exception_string);
        // Print line of source code.
        v8::String::Utf8Value sourceline(message->GetSourceLine());
        const char* sourceline_string = ToCString(sourceline);
        NSLog(@"%s", sourceline_string);
        // Print wavy underline (GetUnderline is deprecated).
        int start = message->GetStartColumn();
        int end = message->GetEndColumn();
        NSMutableString *indent = [NSMutableString stringWithCapacity:end];
        for (int i = 0; i < start; i++)
            [indent appendString:@" "];
        for (int i = start; i < end; i++)
            [indent appendString:@"^"];
        NSLog(@"%@", indent);
        v8::String::Utf8Value stack_trace(try_catch->StackTrace());
        if (stack_trace.length() > 0) {
            const char* stack_trace_string = ToCString(stack_trace);
            NSLog(@"%s", stack_trace_string);
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


static v8::Handle<Value> FRand(const Arguments& args) {
    //v8::Locker lock;
    HandleScope scope;
    return scope.Close(v8::Number::New(rand() / (RAND_MAX + 1.0)));
}

static v8::Handle<Value> Echo(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
    //v8::Locker lock;
    HandleScope scope;
    id obj = nil;
    
    if (args[0]->IsObject())
        obj = (id)args[0]->ToObject()->GetPointerFromInternalField(0);
    
    if (obj) {
        v8::Unlocker unlocker;
        NSLog(@"%@", obj);
    } else {
        v8::Handle<Value> arg = args[0];
        v8::String::Utf8Value value(arg);
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
    v8::Handle<String> output = String::New([xmlString UTF8String], [xmlString length]);
    [pool release];
    return scope.Close(output);
}

static BOOL ExecJSCode(const char *code, uint32_t length, const char *name)
{
    @try {
        HandleScope scope;
        v8::Handle<v8::Value> result;
        v8::TryCatch try_catch;
        Local<String> codeString = String::New(code, length);
        Local<String> nameString = String::New(name);
        v8::Handle<v8::Script> compiledScript = v8::Script::Compile(codeString, nameString);
        if (!compiledScript.IsEmpty()) {
            result = compiledScript->Run();
            if (result.IsEmpty()) {
                ReportException(&try_catch);
            } else {
                return YES;
            }
        } else {
            ReportException(&try_catch);
        }
    } @catch (NSException *e) {
        NSLog(@"%@", e);
    }
    return NO;
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
    BOOL ret = NO;
    if (fh) {
        NSData *data = [fh readDataToEndOfFile];
        ret = ExecJSCode((const char *)[data bytes], [data length], [path UTF8String]);
    }
    [pool release];
    return scope.Close(v8::Boolean::New(ret ? 1 : 0));
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
    //JMXEntity *entity = (JMXEntity *)globalObject->GetPointerFromInternalField(0);
    //v8::Locker::StopPreemption();
    //globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    if (args.Length() >= 1 && args[0]->IsFunction()) {
        v8::Locker::StartPreemption(50);
        while (1) {
            HandleScope iterationScope;
            if (globalObject->GetHiddenValue(String::New("quit"))->BooleanValue())
                break;
            
            Local<Value> global = globalObject->Get(String::New("scriptEntity"));
            if (global.IsEmpty() || global->IsUndefined() || global->IsNull())
                break;                                     
            v8::Local<v8::Object> obj = global->ToObject();

            JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
            //ctx->Global()->Set(String::New("scriptEntity"), [scriptEntity jsObj]);

            if (!entity.active) {
                break;
            }
            v8::Local<v8::Function> foo = v8::Local<v8::Function>::Cast(args[0]);
            int nArgs = args.Length() ? args.Length() - 1 : 0;
            v8::Handle<v8::Value> *fArgs = nArgs
                                         ? (v8::Handle<v8::Value> *)malloc(sizeof(v8::Handle<v8::Value>) * nArgs)
                                         : nil;
            for (int i = 0; i < nArgs; i++)
                fArgs[i] = args[i+1];
            //v8::Local<v8::Value> result = 
            foo->Call(foo, nArgs, fArgs);
            if (fArgs)
                free(fArgs);
            uv_next(uv_default_loop());
        }
        // restore quit status for nested loops
        v8::Locker::StopPreemption();
        globalObject->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    }
    //v8::Locker::StartPreemption(50);
    NSLog(@"Javascript run() is exiting");
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

static v8::Handle<Value> AddToRunLoop(const Arguments& args)
{
    v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    JMXScript *scriptContext = entity.jsContext;
    if (args.Length() >= 2 && args[0]->IsFunction() && args[1]->IsNumber()) {
        JMXScriptTimer *foo = [JMXScriptTimer scriptTimerWithFireDate:[NSDate dateWithTimeIntervalSinceNow:args[1]->NumberValue()]
                                                              interval:args[1]->NumberValue()
                                                                target:scriptContext
                                                              selector:@selector(JSRunLoop:)
                                                               repeats:YES];
        foo.function = Persistent<Function>::New(Handle<Function>::Cast(args[0]));
        foo.function->SetHiddenValue(String::New("lastUpdate"), v8::Number::New([[NSDate date] timeIntervalSince1970]));
        foo.function->SetHiddenValue(String::New("interval"), args[1]);
        [[NSRunLoop currentRunLoop] addTimer:foo.timer forMode:NSRunLoopCommonModes];
        [scriptContext addRunloopTimer:foo];
        return handleScope.Close([foo jsObj]);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> RemoveFromRunLoop(const Arguments& args)
{
    v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    JMXScript *scriptContext = entity.jsContext;
    JMXScriptTimer *foo = (JMXScriptTimer *)Local<Object>::Cast(args[0])->GetPointerFromInternalField(0);
    if (foo && [scriptContext.runloopTimers containsObject:foo]) {
        [foo.timer invalidate];
        [scriptContext removeRunloopTimer:foo];
        return handleScope.Close(v8::Boolean::New(1));
    }
    return handleScope.Close(v8::Boolean::New(0));
}

// TODO - SetInterval and SetTimeout could be both implemented in a single function
static v8::Handle<Value> SetInterval(const Arguments& args)
{
    v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    JMXScript *scriptContext = entity.jsContext;
    if (args.Length() >= 2 && args[1]->IsNumber() && 
        (args[0]->IsString() || args[0]->IsFunction()))
    {
        JMXScriptTimer *foo = [JMXScriptTimer scriptTimerWithFireDate:[NSDate dateWithTimeIntervalSinceNow:args[1]->NumberValue()]
                                                             interval:args[1]->NumberValue()/1000 // millisecs here
                                                               target:scriptContext
                                                             selector:@selector(JSRunLoop:)
                                                              repeats:YES];
        if (args[0]->IsString()) {
            v8::String::Utf8Value statements(args[0]->ToString());
            foo.statements = [NSString stringWithUTF8String:*statements];
        } else {
            foo.function = Persistent<Function>::New(Handle<Function>::Cast(args[0]));
            foo.function->SetHiddenValue(String::New("lastUpdate"), v8::Number::New([[NSDate date] timeIntervalSince1970]));
            foo.function->SetHiddenValue(String::New("interval"), args[1]);
        }
        [[NSRunLoop currentRunLoop] addTimer:foo.timer forMode:NSRunLoopCommonModes];
        [scriptContext addRunloopTimer:foo];
        return handleScope.Close([foo jsObj]);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> SetTimeout(const Arguments& args)
{
    v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    JMXScript *scriptContext = entity.jsContext;
    if (args.Length() >= 2 && args[1]->IsNumber() && 
        (args[0]->IsString() || args[0]->IsFunction()))
    {
        JMXScriptTimer *foo = [JMXScriptTimer scriptTimerWithFireDate:[NSDate dateWithTimeIntervalSinceNow:args[1]->NumberValue()]
                                                             interval:args[1]->NumberValue()/1000 // millisecs here
                                                               target:scriptContext
                                                             selector:@selector(JSRunLoop:)
                                                              repeats:NO];
        
        if (args[0]->IsString()) {
            v8::String::Utf8Value statements(args[0]->ToString());
            foo.statements = [NSString stringWithUTF8String:*statements];
        } else {
            foo.function = Persistent<Function>::New(Handle<Function>::Cast(args[0]));
            foo.function->SetHiddenValue(String::New("lastUpdate"), v8::Number::New([[NSDate date] timeIntervalSince1970]));
            foo.function->SetHiddenValue(String::New("interval"), args[1]);
        }
        [[NSRunLoop currentRunLoop] addTimer:foo.timer forMode:NSRunLoopCommonModes];
        [scriptContext addRunloopTimer:foo];
        return handleScope.Close([foo jsObj]);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> ClearTimeout(const Arguments& args)
{
    v8::Locker locker;
    HandleScope handleScope;
    Local<Context> context = v8::Context::GetCalling();
    Local<Object> globalObject  = context->Global();
    v8::Local<v8::Object> obj = globalObject->Get(String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);
    JMXScript *scriptContext = entity.jsContext;
    JMXScriptTimer *foo = (JMXScriptTimer *)Local<Object>::Cast(args[0])->GetPointerFromInternalField(0);
    if (foo && [scriptContext.runloopTimers containsObject:foo]) {
        [foo.timer invalidate];
        [scriptContext removeRunloopTimer:foo];
        return handleScope.Close(v8::Boolean::New(1));
    }
    return handleScope.Close(v8::Boolean::New(0));
}

@implementation JMXScript

@synthesize scriptEntity, runloopTimers, eventListeners, ctx;

static char *argv[2] = { (char *)"JMX", NULL };

+ (void)initialize
{
    // initialize node.js
    node::Init(1, argv);
    v8::V8::Initialize();
}

+ (BOOL)runScript:(NSString *)source
{
    JMXScript *jsContext = [[self alloc] init];
    BOOL ret = [jsContext runScript:source];
    [jsContext release];
    return ret;}


+ (void)dispatchScript:(NSString *)source
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [self runScript:source];
    [pool drain];
}

// TODO - use a NSOperationQueue
+ (void)runScriptInBackground:(NSString *)source
{
    //[self performSelector:@selector(dispatchScript:) onThread:[JMXContext scriptThread] withObject:arg waitUntilDone:NO];
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
        if (strcmp(mappedClasses[i].className, "JMXPhidgetEncoderEntity") == 0) {
            // XXX - exception case for weakly linked Phidget library
            //       if it's not available at runtime we don't want to register the phidget-related entities
            //       or the application will crash when the user tries accessing them
            if (CPhidgetEncoder_create == NULL)
                continue;
        }
        Class entityClass = NSClassFromString([NSString stringWithUTF8String:mappedClasses[i].className]);
        if (entityClass) {
            [entityClass jsRegisterClassMethods:constructor];
            ctxTemplate->Set(String::New(mappedClasses[i].jsClassName), constructor);
        }
    }
    [pool drain];
}

- (void)JSRunLoop:(NSTimer *)timer
{
    v8::Locker locker;
    HandleScope handleScope;
    v8::Context::Scope context_scope(ctx);
    JMXScriptTimer *foo = timer.userInfo;
    if (foo.statements && [foo.statements length]) {
        ExecJSCode([foo.statements UTF8String], [foo.statements length], "JMXScriptTimeout");
        if (!foo.repeats) {
            [foo.timer invalidate];
            [runloopTimers removeObject:foo];
        }
    } else {
        //@try {
            v8::TryCatch try_catch;
            v8::Handle<Value> ret = foo.function->Call(foo.function, 0, nil);
            if (ret.IsEmpty()) {
                ReportException(&try_catch);
                [foo.timer invalidate];
                [runloopTimers removeObject:foo];
                return;
            }
            foo.function->SetHiddenValue(String::New("lastUpdate"), v8::Number::New([[NSDate date] timeIntervalSince1970]));
            if (!ret->IsTrue() && !foo.repeats) {
                [foo.timer invalidate];
                [runloopTimers removeObject:foo];
            }
        /*} @catch (NSException *e) {
            NSLog(@"%@", e);
        }*/
    }
}

- (v8::Handle<Value>)execFunction:(v8::Handle<v8::Function>)function
       withArguments:(v8::Handle<v8::Value> *)argv
               count:(NSUInteger)count
{
    v8::Locker locker;
    HandleScope handleScope;
    v8::TryCatch try_catch;
    v8::Handle<Value> ret = function->Call(function, count, argv);
    if (ret.IsEmpty()) {
        ReportException(&try_catch);
        return Undefined();
    }
    return handleScope.Close(ret); 
}

- (void)execFunction:(v8::Handle<v8::Function>)function
{
    v8::Locker locker;
    HandleScope handleScope;
    v8::Handle<Value> ret = function->Call(function, 0, nil);
}

- (void)nodejsRun
{
    uint64_t maxDelta = 1e9 / 120.0; // max 120 ticks per seconds
    @try {
        NSThread *currentThread = [NSThread currentThread];
        while (![currentThread isCancelled]) {
            v8::Locker locker;
            v8::HandleScope handle_scope;
            v8::Context::Scope context_scope(ctx);
            uint64_t timeStamp = CVGetCurrentHostTime();
            NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
            //uv_run(uv_default_loop());
            uv_next(uv_default_loop());
            [pool release];
            {
                v8::Unlocker unlocker;
                uint64_t now = CVGetCurrentHostTime();
                uint64_t delta = now - timeStamp;
                uint64_t sleepTime = (delta && delta < maxDelta) ? maxDelta - delta : 0;
                if (sleepTime) {
                    struct timespec time = { 0, 0 };
                    struct timespec remainder = { 0, sleepTime };
                    do {
                        time.tv_sec = remainder.tv_sec;
                        time.tv_nsec = remainder.tv_nsec;
                        remainder.tv_nsec = 0;
                        nanosleep(&time, &remainder);
                    } while (remainder.tv_sec || remainder.tv_nsec);
                }
            }
        }
    }
    @catch (NSException *exception) {
        NSLog(@"%@", exception);
    }
}

- (void)startWithEntity:(JMXScriptEntity *)entity
{
    v8::Locker locker;
    v8::HandleScope handle_scope;
    
    persistentInstances = [[NSMutableDictionary alloc] init];
    Local<ObjectTemplate>ctxTemplate = ObjectTemplate::New();
    
    ctxTemplate->Set(String::New("rand"), FunctionTemplate::New(Rand));
    ctxTemplate->Set(String::New("frand"), FunctionTemplate::New(FRand));
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
    ctxTemplate->Set(String::New("addToRunLoop"), FunctionTemplate::New(AddToRunLoop));
    ctxTemplate->Set(String::New("removeFromRunLoop"), FunctionTemplate::New(RemoveFromRunLoop));
#if 0
    ctxTemplate->Set(String::New("setTimeout"), FunctionTemplate::New(SetTimeout));
    ctxTemplate->Set(String::New("clearTimeout"), FunctionTemplate::New(ClearTimeout));
    
    ctxTemplate->Set(String::New("setInterval"), FunctionTemplate::New(SetInterval));
    ctxTemplate->Set(String::New("clearInterval"), FunctionTemplate::New(ClearTimeout)); // alias for ClearTimeout
#endif
    ctxTemplate->SetInternalFieldCount(1);
    
    /* TODO - think if worth exposing such global functions
     ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
     ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
     */
    [self registerClasses:ctxTemplate];
    ctx = Persistent<Context>::New(Context::New(NULL, ctxTemplate));
    v8::Context::Scope context_scope(ctx);
    
    // Create a new execution environment containing the built-in
    // functions
    scriptEntity = entity;
    ctx->Global()->Set(String::New("scriptEntity"), [scriptEntity jsObj]);
    
    ctx->Global()->SetAccessor(String::New("document"), GetDocument);
    //ctx->Global()->SetPointerInInternalField(0, self);
    runloopTimers = [[NSMutableSet alloc] initWithCapacity:100];
    eventListeners = [[NSMutableDictionary alloc] initWithCapacity:50];
    
    operationQueue = [[NSOperationQueue alloc] init];
    
    // second part of node initialization
    Handle<Object> process = node::SetupProcessObject(1, argv);
    v8_typed_array::AttachBindings(ctx->Global());
    
    // Create all the objects, load modules, do everything.
    // so your next reading stop should be node::Load()!
    node::Load(process);
    
    char baseInclude[] = "include('JMX.js');";
    // Enter the newly created execution environment.
    ExecJSCode(baseInclude, strlen(baseInclude), "JMX");

#if 0
    nodejsRunTimer = [[NSTimer timerWithTimeInterval:0.25 target:self selector:@selector(nodejsRun) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:nodejsRunTimer forMode:NSRunLoopCommonModes];
#else
    nodejsThread = [[NSThread alloc] initWithTarget:self selector:@selector(nodejsRun) object:nil];
    [nodejsThread start];
#endif
}

- (void)clearPersistentInstances
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *objs = [persistentInstances allKeys];
    for (id obj in objs)
        [self removePersistentInstance:obj];
    [pool drain];
}

- (void)clearTimers
{
    [self execCode:@"clearAllTimers()"];
    [nodejsThread cancel];
    [nodejsThread release];
#if 0
    for (JMXScriptTimer *scriptTimer in runloopTimers)
        [scriptTimer.timer invalidate];
    [runloopTimers removeAllObjects];
    [nodejsRunTimer invalidate];
    [nodejsRunTimer release];
#endif
}

- (void)stop
{
    v8::Locker locker;
    v8::HandleScope handle_scope;
    v8::Context::Scope context_scope(ctx);
    
    [self clearTimers];
    // and tell V8 we want to release anything possible (by notifying a low memory condition
    V8::LowMemoryNotification();
    
    if (scriptEntity) {
        if ([scriptEntity conformsToProtocol:@protocol(JMXRunLoop)])
            [scriptEntity performSelector:@selector(stop)];
        scriptEntity = nil;
    }
    [self clearPersistentInstances];
}

- (void)dealloc
{
    v8::Locker locker;
    v8::HandleScope handle_scope;
    v8::Context::Scope context_scope(ctx);

    // and tell V8 we want to release anything possible (by notifying a low memory condition
    V8::LowMemoryNotification();

    ctx->Global()->Delete(String::New("scriptEntity"));
    ctx->Global().Clear();
    //contextes.erase(self);
    ctx.Dispose();
    ctx.Clear();
    // notify that we have disposed the context
    V8::ContextDisposedNotification();    
    while( !V8::IdleNotification() )
        ;
    
    [persistentInstances release];
    [runloopTimers release];
    [eventListeners release];
    [operationQueue release];
    [super dealloc];
}

- (void)execCode:(NSString *)code
{
    BOOL ret = ExecJSCode((const char *)[code UTF8String], [code length], "code");
    if (!ret) {
        // TODO - handle error conditions
    }
}

- (BOOL)runScript:(NSString *)script
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Locker locker;
    v8::HandleScope handle_scope;
    
    v8::Context::Scope context_scope(ctx);
    
    //NSLog(@"%@", [self exportGraph:[[JMXContext sharedContext] allEntities] andPins:nil]);
    ctx->Global()->SetHiddenValue(String::New("quit"), v8::Boolean::New(0));
    BOOL ret = ExecJSCode([script UTF8String], [script length],
                          scriptEntity ? [scriptEntity.label UTF8String] : [[NSString stringWithFormat:@"%@", self] UTF8String]);
    
    [pool drain];
    return ret;
}

+ (JMXScript *)getContext
{
    JMXScript *context = nil;
    HandleScope handleScope;
    Local<Context> c = v8::Context::GetCurrent();
    Local<Object> globalObject  = c->Global();
    v8::Local<v8::Object> obj = globalObject->Get(v8::String::New("scriptEntity"))->ToObject();
    JMXScriptEntity *entity = (JMXScriptEntity *)obj->GetPointerFromInternalField(0);

    context = entity.jsContext;
    return context;
}

- (v8::Handle<v8::Value>)getPersistentInstance:(id)obj
{
    HandleScope handleScope;
    JMXPersistentInstance *p = nil;
    id key;
    if ([obj respondsToSelector:@selector(hashString)])
        key = [obj hashString];
    else
        key = obj;
    p = (JMXPersistentInstance *)[[persistentInstances objectForKey:key] pointerValue];
    if (p) {
        return handleScope.Close(p->jsObj);
    }
    return handleScope.Close(Undefined());
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
    NSDebug(@"Releasing Persistent Instance: %@ (%lu)", p->obj, (unsigned long)[p->obj retainCount]);
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
        free(p);
    }
}

- (void)addRunloopTimer:(JMXScriptTimer *)timer
{
    [runloopTimers addObject:timer];
}
- (void)removeRunloopTimer:(JMXScriptTimer *)timer
{
    [runloopTimers removeObject:timer];
}

- (void)addListener:(JMXEventListener *)listener forEvent:(NSString *)event
{
    NSMutableSet *listeners = [eventListeners objectForKey:event];
    if (!listeners) {
        listeners = [[[NSMutableSet alloc] initWithCapacity:50] autorelease];
        [eventListeners setObject:listeners forKey:event];
    }
    [listeners addObject:listener];
}
- (void)removeListener:(JMXEventListener *)listener forEvent:(NSString *)event
{
    NSMutableSet *listeners = [eventListeners objectForKey:event];
    if (listeners)
        [listeners removeObject:event];
}

- (BOOL)dispatchEvent:(JMXEvent *)anEvent toTarget:(NSXMLNode *)aTarget
{
    // TODO - support capturing
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableSet *listeners = [eventListeners objectForKey:anEvent.type];
    for (JMXEventListener *listener in listeners) {
        if ([listener.target isEqual:aTarget]) {
            Locker locker;
            HandleScope handleScope;
            v8::Context::Scope context_scope(ctx);
            Handle<Value> args[1];
            args[0] = [anEvent jsObj];
            [self execFunction:listener.function withArguments:args count:1];
            //[listener dispatch];
        }
    }
    [pool release];
    return NO;
}

- (BOOL)dispatchEvent:(JMXEvent *)anEvent
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSMutableSet *listeners = [eventListeners objectForKey:anEvent.type];
    Locker locker;
    HandleScope handleScope;
    v8::Context::Scope context_scope(ctx);
    Handle<Value> args[1];
    args[0] = [anEvent jsObj];
    for (JMXEventListener *listener in listeners) {
        Unlocker unlocker;
        [self execFunction:listener.function withArguments:args count:1];
    }
    [pool release];
    return NO;
}

#ifdef EXPORT_GRAPH_ENABLED
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
#endif

@end
