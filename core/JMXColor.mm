//
//  JMXColor.m
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXColor.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXColor
+ (v8::Handle<FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<FunctionTemplate> classTemplate = FunctionTemplate::New();
    classTemplate->SetClassName(String::New("Color"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();

    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = classTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("redComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("blueComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("greenComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("whiteComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("blackComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("alphaComponent"), GetDoubleProperty);
    return handleScope.Close(classTemplate);
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXColor jsClassTemplate];
    v8::Handle<Object> jsInstance = classTemplate->InstanceTemplate()->NewInstance();
    v8::Handle<External> external_ptr = External::New(self);
    jsInstance->SetInternalField(0, external_ptr);
    return handle_scope.Close(jsInstance);
}

@end

void JMXColorJSDestructor(Persistent<Value> object, void *parameter)
{
    NSLog(@"V8 WeakCallback called");
    JMXColor *obj = static_cast<JMXColor *>(parameter);
    Local<Context> currentContext  = v8::Context::GetCurrent();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        /* this will destroy the javascript object as well */
        [ctx removePersistentInstance:obj];
    } else {
        NSLog(@"Can't find context to attach persistent instance (just leaking)");
    }
}

//static std::map<JMXPoint *, v8::Persistent<v8::Object> > instancesMap;

v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args)
{
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXColor jsClassTemplate];
    double r = 0;
    double g = 0;
    double b = 0;
    double a = 0;
    if (args.Length() >= 3) {
        r = args[0]->NumberValue();
        g = args[1]->NumberValue();
        b = args[2]->NumberValue();
        // get alpha
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(classTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXColor *color = [[JMXColor colorWithDeviceRed:r green:g blue:b alpha:1.0] retain];
    jsInstance.MakeWeak(color, &JMXColorJSDestructor);
    //instancesMap[point] = jsInstance;
    v8::Handle<External> external_ptr = External::New(color);
    jsInstance->SetInternalField(0, external_ptr);
    Local<Context> currentContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        [ctx addPersistentInstance:jsInstance obj:color];
    } else {
        NSLog(@"Can't find context to attach persistent instance (just leaking)");
    }
    [pool release];
    return handle_scope.Close(jsInstance);
}
