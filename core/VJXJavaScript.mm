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
#import "VJXQtVideoCaptureLayer.h"
#import "VJXQtVideoLayer.h"
#import "VJXAudioFileLayer.h"
#import "VJXCoreAudioOutput.h"

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
    HandleScope scope;
    v8::Handle<Object> pinObj = args[0]->ToObject();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::String::Utf8Value proto(pinObj->ToString());
    NSString *objectType = [NSString stringWithUTF8String:*proto];
    if ([objectType isEqualToString:@"[object Pin]"]) {
        Local<External> wrap = Local<External>::Cast(pinObj->GetInternalField(0));
        VJXOutputPin *pin = (VJXOutputPin *)wrap->Value();
        Local<Context> globalContext = v8::Context::GetCurrent();
        Local<Object> globalObject  = globalContext->Global();
        if (!globalObject.IsEmpty()) {
            VJXEntity *scriptEntity = (VJXEntity *)globalObject->GetPointerFromInternalField(0);
            if (scriptEntity)
                [scriptEntity proxyOutputPin:pin];
            return v8::Boolean::New(1);
        }
    } else {
        NSLog(@"(exportPin) Bad argument: %@", objectType);
    }
    [pool drain];
    return v8::Boolean::New(0);
}

static void ReportException(v8::TryCatch* try_catch) {
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
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSLog(@"%s", *value);
    return v8::Undefined();
}

static v8::Handle<Value> Include(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
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
    if (args.Length() >= 1) // XXX - ignore extra parameters
        [NSThread sleepForTimeInterval:args[0]->NumberValue()];
    v8::Handle<Primitive> t = Undefined();
    return reinterpret_cast<v8::Handle<String>&>(t);
}


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

// TODO - use a NSOperationQueue
+ (void)runScriptInBackground:(NSString *)source {
    [self performSelector:@selector(runScript:) onThread:[VJXContext scriptThread] withObject:source waitUntilDone:NO];
}

- (void)registerClasses:(v8::Handle<ObjectTemplate>)ctxTemplate;
{
    HandleScope handle_scope;
    // register the VJXVideoOutput class
    ctxTemplate->Set(String::New("OpenGLScreen"), FunctionTemplate::New(VJXOpenGLScreenJSConstructor));
    ctxTemplate->Set(String::New("VideoCapture"), FunctionTemplate::New(VJXQtVideoCaptureLayerJSConstructor));
    ctxTemplate->Set(String::New("VideoLayer"), FunctionTemplate::New(VJXQtVideoLayerJSConstructor));
    ctxTemplate->Set(String::New("AudioLayer"), FunctionTemplate::New(VJXAudioFileLayerJSConstructor));
    ctxTemplate->Set(String::New("AudioOutput"), FunctionTemplate::New(VJXCoreAudioOutputJSConstructor));


}

- (id)init
{
    self = [super init];
    if (self) {
        HandleScope handle_scope;
        // Create a template for the global object.
        v8::Handle<ObjectTemplate>ctxTemplate = ObjectTemplate::New();
        ctxTemplate->Set(String::New("echo"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("print"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("include"), FunctionTemplate::New(Include));
        ctxTemplate->Set(String::New("sleep"), FunctionTemplate::New(Sleep));
        ctxTemplate->Set(String::New("lsdir"), FunctionTemplate::New(ListDir));
        ctxTemplate->Set(String::New("isdir"), FunctionTemplate::New(IsDir));
        ctxTemplate->Set(String::New("exportPin"), FunctionTemplate::New(ExportPin));
        /*
        ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
        ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        */
        [self registerClasses:ctxTemplate];
        // Create a new execution environment containing the built-in
        // functions
        ctx = Context::New(NULL, ctxTemplate);
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
    if (scriptEntity)
        [scriptEntity release];
    [super dealloc];
}

- (void)runScript:(NSString *)source
{
    return [self runScript:source withEntity:nil];
}

- (void)runScript:(NSString *)script withEntity:(VJXEntity *)entity
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::HandleScope handle_scope;
    
    v8::Context::Scope context_scope(ctx);
    if (entity) {
        scriptEntity = [entity retain];
        Local<Object> globalObject = ctx->Global();
        globalObject->SetPointerInInternalField(0, scriptEntity);
    }
    v8::TryCatch try_catch;
    v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New([script UTF8String]), String::New("VJXScript"));
    if (!compiledScript.IsEmpty()) {
        compiledScript->Run();
    } else {
        String::Utf8Value error(try_catch.Exception());
        NSLog(@"%s", *error);
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
}

@end

v8::Handle<Value>accessStringProperty(Local<String> name, const AccessorInfo& info)
{
    HandleScope handle_scope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    id obj = (id)field->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value value(name);
    NSString *property = [NSString stringWithUTF8String:*value];
    NSString *output = nil;
    SEL selector = NSSelectorFromString(property);
    if ([obj respondsToSelector:selector])
        output = [obj performSelector:selector];
    else 
        NSLog(@"Unknown property %@", property);
    [pool drain];
    if (output)
        return handle_scope.Close(String::New([output UTF8String], [output length]));
    else
        return Undefined();
    
}

v8::Handle<Value>accessNumberProperty(Local<String> name, const AccessorInfo& info)
{
    HandleScope handle_scope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    id obj = (id)field->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value value(name);
    NSString *property = [NSString stringWithUTF8String:*value];
    NSNumber *output = nil;
    SEL selector = NSSelectorFromString(property);
    if ([obj respondsToSelector:selector])
        output = [obj performSelector:selector];
    else 
        NSLog(@"Unknown property %@", property);
    [pool drain];
    if (output)
        return handle_scope.Close(Number::New([output doubleValue]));
    else
        return Undefined();
}

v8::Handle<Value>accessBoolProperty(Local<String> name, const AccessorInfo& info)
{
    HandleScope handle_scope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    id obj = (id)field->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value value(name);
    NSString *property = [NSString stringWithUTF8String:*value];
    SEL selector = NSSelectorFromString(property);
    if (![obj respondsToSelector:selector]) {
        NSLog(@"Unknown property %@", property);
        [pool drain];
        return Undefined();
    }
    [pool drain];
    return handle_scope.Close(v8::Boolean::New([obj performSelector:selector]));
}
