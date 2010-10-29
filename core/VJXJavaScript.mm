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
#import "VJXVideoOutput.h"

@class VJXEntity;

using namespace v8;
using namespace std;

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
    
    return String::New([output UTF8String]);
    
}

@implementation VJXJavaScript

- (void)registerClasses
{
    
    /**
     * Utility function that wraps a C++ http request object in a
     * JavaScript object.
     */

    Context::Scope context_scope(ctx);
          
    // register the VJXVideoOutput class
    v8::Handle<FunctionTemplate> entityClassTemplate = [VJXVideoOutput makeClassTemplate];
    ctx->Global()->Set(String::New("Entity"), entityClassTemplate->GetFunction());

}

- (id)init
{
    self = [super init];
    if (self) {
        HandleScope handle_scope;
        // Create a template for the global object.
        v8::Handle<ObjectTemplate> global = ObjectTemplate::New();
        global->Set(String::New("ListEntities"), FunctionTemplate::New(ListEntities));
        /*
        // Bind the global 'print' function to the C++ Print callback.
        global->Set(String::New("print"), FunctionTemplate::New(Print));
        // Bind the global 'read' function to the C++ Read callback.
        global->Set(String::New("read"), FunctionTemplate::New(Read));
        // Bind the global 'load' function to the C++ Load callback.
        global->Set(String::New("load"), FunctionTemplate::New(Load));
        // Bind the 'quit' function
        global->Set(String::New("quit"), FunctionTemplate::New(Quit));
        // Bind the 'version' function
        global->Set(String::New("version"), FunctionTemplate::New(Version));
         */
        // Create a new execution environment containing the built-in
        // functions
        //Handle<Context> context = Context::New(NULL, global);
        ctx = Context::New(NULL, global);

        // Enter the newly created execution environment.
    }
    return self;
}

- (void)dealloc
{
    ctx.Dispose();
    [super dealloc];
}

@end
