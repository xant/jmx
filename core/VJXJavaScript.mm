//
//  VJXJavaScript.m
//  VeeJay
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

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

@class VJXEntity;

using namespace v8;
using namespace std;

typedef std::map<id, v8::Persistent<v8::Object> > InstMap;
typedef std::pair< VJXJavaScript *, Persistent<Context> >CtxPair;
typedef std::map< VJXJavaScript *, Persistent<Context> > CtxMap;
CtxMap contextes;

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
    NSString *path = [NSString stringWithUTF8String:*value];
    NSFileHandle *fh = [NSFileHandle fileHandleForReadingAtPath:path];
    if (fh) {
        NSData *data = [fh readDataToEndOfFile];
        v8::TryCatch try_catch;
        v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New((const char *)[data bytes]), String::New([path UTF8String]));
        if (!compiledScript.IsEmpty()) {
            compiledScript->Run();
        } else {
            String::Utf8Value error(try_catch.Exception());
            NSLog(@"%s", *error);
        }
        
    }
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

+ (void)runScript:(NSString *)script
{
    VJXJavaScript *jsContext = [[self alloc] init];
    [jsContext runScript:script];
}

// TODO - use a NSOperationQueue
+ (void)runScriptInBackground:(NSString *)script {
    NSThread *scriptThread = [[[NSThread alloc] initWithTarget:self selector:@selector(runScript:) object:script] autorelease];
    [scriptThread start];
}

- (void)registerClasses:(v8::Handle<ObjectTemplate>)ctxTemplate;
{
    /**
     * Utility function that wraps a C++ http request object in a
     * JavaScript object.
     */
    HandleScope handle_scope;
    // register the VJXVideoOutput class
    ctxTemplate->Set(String::New("OpenGLScreen"), FunctionTemplate::New(VJXOpenGLScreenJSConstructor));
    ctxTemplate->Set(String::New("VideoCapture"), FunctionTemplate::New(VJXQtVideoCaptureLayerJSConstructor));
    ctxTemplate->Set(String::New("VideoLayer"), FunctionTemplate::New(VJXQtVideoLayerJSConstructor));

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
        /*
        ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
        ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        */
        [self registerClasses:ctxTemplate];
        // Create a new execution environment containing the built-in
        // functions
        ctx = Context::New(NULL, ctxTemplate);
        contextes[self] = ctx;
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
    [super dealloc];
}

- (void)runScript:(NSString *)script
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::HandleScope handle_scope;
    
    v8::Context::Scope context_scope(ctx);
    
    v8::TryCatch try_catch;
    v8::Handle<v8::Script> compiledScript = v8::Script::Compile(String::New([script UTF8String]), String::New("CIAO"));
    if (!compiledScript.IsEmpty()) {
        compiledScript->Run();
    } else {
        String::Utf8Value error(try_catch.Exception());
        NSLog(@"%s", *error);
    }
    [pool drain];
    [self release];
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
