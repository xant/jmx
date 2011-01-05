//
//  JMXNode.h
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"

#ifndef __JMXV8__

/*!
 @define JMXV8_EXPORT_NODE_CLASS
 @abstract define both the constructor and the descructor for the mapped class
 @param __class
 */
#define JMXV8_EXPORT_NODE_CLASS(__class)
/*!
 @define JMXV8_DECLARE_NODE_CONSTRUCTOR
 @abstract define the constructor for the mapped class
 @param __class
 */
#define JMXV8_DECLARE_NODE_CONSTRUCTOR(__class)

#else

#import "NSXMLNode+V8.h"

#define JMXV8_EXPORT_NODE_CLASS(__class) \
using namespace v8;\
static Persistent<FunctionTemplate> objectTemplate;\
/*static std::map<__class *, v8::Persistent<v8::Object> > instancesMap;*/\
void __class##JSDestructor(Persistent<Value> object, void *parameter)\
{\
    NSLog(@"V8 WeakCallback called");\
    __class *obj = static_cast<__class *>(parameter);\
    Local<Context> currentContext  = v8::Context::GetCurrent();\
    JMXScript *ctx = [JMXScript getContext:currentContext];\
    if (ctx) {\
    /* this will destroy the javascript object as well */\
    [ctx removePersistentInstance:obj];\
    } else {\
        NSLog(@"Can't find context to attach persistent instance (just leaking)");\
    }\
}\
\
v8::Handle<Value> __class##JSConstructor(const Arguments& args)\
{\
    /*HandleScope handleScope;*/\
    if (objectTemplate.IsEmpty())\
        objectTemplate = [__class jsObjectTemplate];\
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());\
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];\
    __class *instance = [[__class alloc] init];\
    if ([instance respondsToSelector:@selector(jsInit:)]) {\
        NSValue *argsValue = [NSValue valueWithPointer:(void *)&args];\
        [instance performSelector:@selector(jsInit:) withObject:argsValue];\
    }\
    /* make the handle weak, with a callback */\
    jsInstance.MakeWeak(instance, &__class##JSDestructor);\
    /*instancesMap[instance] = jsInstance;*/\
    jsInstance->SetPointerInInternalField(0, instance);\
    v8::Local<Context> currentContext = v8::Context::GetCalling();\
    JMXScript *ctx = [JMXScript getContext:currentContext];\
    if (ctx) {\
        [ctx addPersistentInstance:jsInstance obj:instance];\
    } else {\
        NSLog(@"Can't find context to attach persistent instance (just leaking)");\
    }\
    [pool release];\
    return jsInstance;\
}

#define JMXV8_DECLARE_NODE_CONSTRUCTOR(__class)\
v8::Handle<v8::Value> __class##JSConstructor(const v8::Arguments& args);

#endif

@interface JMXNode : NSXMLElement {

}

+ (id)nodeWithName:(NSString *)aName;
- (id)initWithName:(NSString *)aName;

#ifdef __JMXV8__
v8::Persistent<v8::FunctionTemplate>JMXNodeJSConstructor();
+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate;
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
#endif

@end
