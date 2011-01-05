//
//  JMXNode.mm
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXNode.h"
#import "JMXScript.h"

@implementation JMXNode

+ (id)nodeWithName:(NSString *)aName
{
    return [[[self alloc] initWithName:aName] autorelease];
}

- (id)initWithName:(NSString *)aName
{
    self = [super initWithName:aName];
    if (self) {
    }
    return self;
}

#pragma mark V8

using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    return [super jsObjectTemplate];
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    return [super jsRegisterClassMethods:constructor];
}

void JMXNodeJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXNode *obj = static_cast<JMXNode *>(parameter);
    //NSLog(@"V8 WeakCallback (Point) called %@", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

v8::Handle<v8::Value> JMXNodeJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    //v8::Locker locker;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXNode jsObjectTemplate];
    Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXNode *node = [[JMXNode alloc] initWithName:@"node"];
    jsInstance.MakeWeak(node, JMXNodeJSDestructor);
    jsInstance->SetPointerInInternalField(0, node);
    [pool drain];
    return handleScope.Close(jsInstance);
}

@end
