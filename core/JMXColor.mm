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

static v8::Persistent<FunctionTemplate> classTemplate;

+ (v8::Persistent<FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    //v8::Handle<FunctionTemplate> classTemplate = FunctionTemplate::New();
    
    if (!classTemplate.IsEmpty())
        return classTemplate;
    
    classTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
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
    return classTemplate;
}

- (void)dealloc
{
    [super dealloc];
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXColor jsClassTemplate];
    v8::Handle<Object> jsInstance = classTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetInternalField(0, External::New(self));
    return handle_scope.Close(jsInstance);
}

@end

void JMXColorJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXColor *obj = static_cast<JMXColor *>(parameter);
    //NSLog(@"V8 WeakCallback (Color) called");
    [obj release];
    object.Dispose();
    object.Clear();
}

v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args)
{
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXColor jsClassTemplate];
    double r = 0.0;
    double g = 0.0;
    double b = 0.0;
    double a = 1.0;
    if (args.Length() >= 3) {
        r = args[0]->NumberValue();
        g = args[1]->NumberValue();
        b = args[2]->NumberValue();
        if (args.Length() >= 4)
            a = args[3]->NumberValue();
        else
            a = 1.0;
    }
    //v8::Handle<Object>jsInstance = classTemplate->InstanceTemplate()->NewInstance();
    Persistent<Object>jsInstance = Persistent<Object>::New(classTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXColor *color = [[JMXColor colorWithDeviceRed:r green:g blue:b alpha:a] retain];
    jsInstance.MakeWeak(color, JMXColorJSDestructor);
    //instancesMap[point] = jsInstance;
    jsInstance->SetInternalField(0, External::New(color));
    [pool release];
    return handle_scope.Close(jsInstance);
}
