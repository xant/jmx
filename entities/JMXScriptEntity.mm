//
//  JMXScriptEntity.mm
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXScriptEntity.h"
#import "JMXScript.h"
#import "JMXProxyPin.h"
#import "JMXGraphFragment.h"

using namespace v8;

@implementation JMXScriptEntity

@synthesize code, jsContext, executionThread;

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
        self.label = @"ScriptEntity";
    }
    return self;
}

- (void)dealloc
{
    [jsContext clearTimers];
    [jsContext release];
    [executionThread release];;
    [super dealloc];
}

- (void)resetContext
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // we want to release our context.
    // first thing ... let's detach all entities we have created
    for (NSXMLNode *node in [self children]) {
        if ([node isKindOfClass:[JMXProxyPin class]]) {
            [self unregisterPin:(JMXPin *)node]; // XXX - this cast is only to avoid a warning
        } else if ([node isKindOfClass:[JMXGraphFragment class]]) {
            for (JMXEntity *entity in [node children]) {
                [entity detach];
            }
            [node detach];
        } 
    }
    if (jsContext) {
        [jsContext clearTimers];
        [jsContext release];
        jsContext = nil;
    }
    [pool drain];
}

- (BOOL)exec
{
    if (!jsContext)
        jsContext = [[JMXScript alloc] init];
    [executionThread release];
    executionThread = [[NSThread currentThread] retain];
    return [jsContext runScript:self.code withEntity:self];
}

- (void)hookEntity:(JMXEntity *)entity
{
    NSArray *elements = [self elementsForName:@"Entities"];
    JMXElement *holder = [elements count] ? [elements objectAtIndex:0] : nil;
    if (!holder) {
        holder = [[JMXGraphFragment alloc] initWithName:@"Entities"];
        [self addChild:holder];
    }
    [holder addChild:entity];
}

static Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    NSLog(@"JMXScriptEntity objectTemplate created");
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("ScriptEntity"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();

   instanceTemplate->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    instanceTemplate->SetInternalFieldCount(1);
    return objectTemplate;
}

@end
