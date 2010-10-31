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

@class VJXEntity;

using namespace v8;
using namespace std;

static v8::Handle<Value> Echo(const Arguments& args) {
    if (args.Length() < 1) return v8::Undefined();
    HandleScope scope;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSLog(@"%s", *value);
    return v8::Undefined();
}

static v8::Handle<Value> ListEntities(const Arguments& args)
{
    NSString *output = [NSString string];
    NSArray *entities;
    {
#ifdef SUPPORT_DEBUGGING
        Unlocker unlocker;
#endif
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

@implementation VJXJavaScript

- (void)registerClasses:(v8::Handle<ObjectTemplate>)ctxTemplate;

{
    
    /**
     * Utility function that wraps a C++ http request object in a
     * JavaScript object.
     */
    HandleScope handle_scope;
    // register the VJXVideoOutput class
    ctxTemplate->Set(String::New("OpenGLScreen"), FunctionTemplate::New(VJXOpenGLScreenJSContructor));

}

- (id)init
{
    self = [super init];
    if (self) {
        HandleScope handle_scope;
        // Create a template for the global object.
        v8::Handle<ObjectTemplate>ctxTemplate = ObjectTemplate::New();
        ctxTemplate->Set(String::New("echo"), FunctionTemplate::New(Echo));
        /*
        ctxTemplate->Set(String::New("print"), FunctionTemplate::New(Echo));
        ctxTemplate->Set(String::New("printf"), FunctionTemplate::New(Printf));
        ctxTemplate->Set(String::New("include"), FunctionTemplate::New(Include));
        ctxTemplate->Set(String::New("AvailableEntities"), FunctionTemplate::New(AvailableEntities));
        ctxTemplate->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        */
        [self registerClasses:ctxTemplate];
        // Create a new execution environment containing the built-in
        // functions
        ctx = Context::New(NULL, ctxTemplate);
        
        // Enter the newly created execution environment.
    }
    return self;
}

- (void)dealloc
{
    ctx.Dispose();
    [super dealloc];
}

- (void)runScript:(NSString *)source
{
    v8::HandleScope handle_scope;
    
    v8::Context::Scope context_scope(ctx);
    
    v8::TryCatch try_catch;
    v8::Handle<v8::Script> script = v8::Script::Compile(String::New([source UTF8String]), String::New("CIAO"));
    if (!script.IsEmpty()) {
        script->Run();
    } else {
        String::Utf8Value error(try_catch.Exception());
        NSLog(@"%s", *error);
    }
}

@end
