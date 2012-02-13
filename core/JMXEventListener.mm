//
//  JMXEventListener.m
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXEventListener.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXEventListener
@synthesize target, capture, function;

- (void)dealloc
{
    self.target = nil;
}

- (void)dispatch
{
    /*
    v8::Locker lock;
    HandleScope handleScope;
    TryCatch tryCatch;
    v8::Handle<Value> ret = function->Call(function, 0, nil);
    if (ret.IsEmpty()) {
        String::Utf8Value error(tryCatch.Exception());
        NSLog(@"%s", *error);
    }*/
}

#pragma mark V8

static v8::Handle<Value> HandleEvent(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXEventListener *listener = (JMXEventListener *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() && args[0]->IsObject() && [listener isKindOfClass:[JMXEventListener class]]) {
        Handle<Object> obj = args[0]->ToObject();
        {
            TryCatch tryCatch;
            v8::Handle<Value> ret = listener.function->Call(listener.function, 0, nil);
            if (ret.IsEmpty()) {
                String::Utf8Value error(tryCatch.Exception());
                NSLog(@"%s", *error);
            }
        }
    }
    return handleScope.Close(Undefined()); // XXX
}


static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Event"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("handleEvent", FunctionTemplate::New(HandleEvent));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);

    // TODO - date properties
    
    return objectTemplate;
}

static void JMXEventListenerJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    Locker lock;
    JMXEvent *obj = static_cast<JMXEvent *>(parameter);
    //NSLog(@"V8 WeakCallback (Rect) called %@", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (Handle<Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    Handle<FunctionTemplate> objectTemplate = [JMXEventListener jsObjectTemplate];
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    jsInstance.MakeWeak([self retain], JMXEventListenerJSDestructor);
    return handle_scope.Close(jsInstance);
}

@end
