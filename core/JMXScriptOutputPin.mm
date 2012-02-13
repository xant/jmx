//
//  JMXScriptOutputPin.m
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXScriptOutputPin.h"
#import "JMXScript.h"
#import "JMXScriptEntity.h"

using namespace v8;

@implementation JMXScriptOutputPin

@synthesize function;

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("OutputPin"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    //classProto->Set("connect", FunctionTemplate::New(connect));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    NSLog(@"JMXOutputPin objectTemplate created");
    return objectTemplate;
}

void JMXOutputPinJSDestructor(v8::Persistent<Value> object, void *parameter)
{
    v8::HandleScope handle_scope;
    v8::Locker lock;
    JMXOutputPin *obj = static_cast<JMXOutputPin *>(parameter);
    //NSLog(@"V8 WeakCallback (Point) called %@", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

v8::Handle<v8::Value> JMXOutputPinJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    //v8::Locker locker;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXOutputPin jsObjectTemplate];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSString *label = @"inputPin";
    JMXPinType type = kJMXVoidPin;
    
    NSString *typeName = @"Void";
    int argsCount = args.Length();
    if (argsCount >= 1) {
        String::Utf8Value str(args[0]->ToString());
        label = [NSString stringWithUTF8String:*str];
    }
    if (argsCount >= 2) {
        String::Utf8Value str(args[1]->ToString());
        typeName = [NSString stringWithUTF8String:*str];
    }
    
    if ([typeName isEqualToString:@"String"]) {
        type = kJMXStringPin;
    } else if ([typeName isEqualToString:@"Text"]) {
        type = kJMXTextPin;
    } else if ([typeName isEqualToString:@"Code"]) {
        type = kJMXCodePin;
    } else if ([typeName isEqualToString:@"Number"]) {
        type = kJMXNumberPin;
    } else if ([typeName isEqualToString:@"Point"]) {
        type = kJMXPointPin;
    } else if ([typeName isEqualToString:@"Color"]) {
        type = kJMXColorPin;
    } else if ([typeName isEqualToString:@"Image"]) {
        type = kJMXImagePin;
    } else if ([typeName isEqualToString:@"Boolean"]) {
        type = kJMXBooleanPin;
    } else if ([typeName isEqualToString:@"Void"]) {
        type = kJMXVoidPin;
    } else {
        NSLog(@"Invalid pin type %@", typeName);
        [pool drain];
        return Undefined();
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    v8::Local<Context> globalContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext:globalContext];
    if (ctx && ctx.scriptEntity) {
        JMXScriptOutputPin *pin = [ctx.scriptEntity registerJSOutputPinWithLabel:label
                                                                    type:type
                                                                function:Persistent<Function>::New(Handle<Function>::Cast(args[2]))];
        
        jsInstance.MakeWeak(pin, JMXOutputPinJSDestructor);
        jsInstance->SetPointerInInternalField(0, pin);
    }

    [pool drain];    
    return handleScope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
}
@end
