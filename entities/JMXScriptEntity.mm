//
//  JMXScriptEntity.mm
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptEntity.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXScriptEntity

@synthesize code;

+ (void)initialize
{
    // note that we are called also when subclasses are initialized
    // and we don't want to register global functions multiple times
    if (self == [JMXScriptEntity class]) {
        
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        active = NO;
        jsContext = [[JMXScript alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [jsContext release];
    [super dealloc];
}

- (void)exec
{
    [jsContext runScript:self.code withEntity:self];
}

static Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    NSLog(@"JMXScriptEntity objectTemplate created");
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("ThreadedEntity"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    return objectTemplate;
}

@end
