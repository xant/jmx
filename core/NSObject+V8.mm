//
//  NSObject+V8.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//
#define __JMXV8__
#import "NSObject+V8.h"

@implementation NSObject (JMXV8)

#pragma mark V8

using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    // do nothing for now
}

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->SetClassName(String::New("JMXObject"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    //classProto->Set("insertBefore", FunctionTemplate::New(InsertBefore));
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // set instance accessors
    //instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty, SetStringProperty);
    
        NSDebug(@"JMXObject objectTemplate created");
    return objectTemplate;
}

static void JMXObjectJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    id obj = static_cast<id>(parameter);
    NSDebug(@"V8 WeakCallback (%@) called ", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXObjectJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    //[ctx addPersistentInstance:jsInstance obj:self];
    return handle_scope.Close(jsInstance);
}

- (id)jmxInit
{
    return [self init];
}

@end
