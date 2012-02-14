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
#import "JMXScriptInputPin.h"
#import "JMXScriptOutputPin.h"
#import "JMXImageData.h"
#import "NSColor+V8.h"
#import "JMXScriptPinWrapper.h"

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
        pinWrappers = [[NSMutableSet alloc] initWithCapacity:25];
    }
    return self;
}

- (void)dealloc
{
    [jsContext clearTimers];
    [jsContext release];
    [executionThread release];
    for (JMXScriptPinWrapper *wrapper in pinWrappers)
        [wrapper disconnect];
    [pinWrappers release];
    [super dealloc];
}

- (BOOL)wrapPin:(JMXPin *)pin withFunction:(v8::Persistent<v8::Function>)function
{
    JMXScriptPinWrapper *wrapper = [JMXScriptPinWrapper pinWrapperWithName:@"jsFunction"
                                                            function:function
                                                              scriptEntity:self];
    [wrapper connectToPin:pin];
    [pinWrappers addObject:wrapper];
    return YES; // XXX
}

- (void)resetContext
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    if (jsContext) {
        [jsContext clearTimers];
        [jsContext release];
        jsContext = nil;
    }
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

- (JMXScriptInputPin *)registerJSInputPinWithLabel:(NSString *)aLabel
                                        type:(JMXPinType)type
                                    function:(v8::Persistent<v8::Function>)function
{
    //JMXInputPin *pin = [self registerInputPin:aLabel withType:type];
    JMXScriptInputPin *pin = [[[JMXScriptInputPin alloc] initWithLabel:aLabel andType:type ownedBy:self withSignal:nil] autorelease];
    pin.function = function;
    [self registerInputPin:pin];
    return pin;
}

- (JMXScriptOutputPin *)registerJSOutputPinWithLabel:(NSString *)aLabel
                                          type:(JMXPinType)type
                                      function:(v8::Persistent<v8::Function>)function
{
    JMXScriptOutputPin *pin = [[[JMXScriptOutputPin alloc] initWithLabel:aLabel andType:type ownedBy:self withSignal:nil] autorelease];
    pin.function = function;
    [self registerOutputPin:pin];
    return pin;
}

#pragma mark -
#pragma JMXPinOwner
- (id)provideDataToPin:(JMXOutputPin *)aPin
{
    if ([aPin isKindOfClass:[JMXScriptOutputPin class]]) {
        JMXScriptOutputPin *pin = (JMXScriptOutputPin *)aPin;
        if (pin.function.IsEmpty() || pin.function->IsNull() || pin.function->IsUndefined())
            return nil;
        Locker locker;
        HandleScope handleScope;
        Handle<Value> args[1];
        v8::Context::Scope context_scope(jsContext.ctx);
        args[0] = [pin jsObj];
        Handle<Value> ret = [jsContext execFunction:pin.function withArguments:args count:1];
        if (ret.IsEmpty()) {
            return nil;
        } else if (ret->IsNumber()) {
            return [NSNumber numberWithDouble:ret->ToNumber()->NumberValue()];
        } else if (ret->IsString()) {
            String::Utf8Value str(ret->ToString());
            return [NSString stringWithUTF8String:*str];
        } else if (ret->IsObject()) {
            return (id)ret->ToObject()->GetPointerFromInternalField(0);
        }
    } else {
        return [super provideDataToPin:aPin];
    }
    return nil;
}

- (void)receiveData:(id)data fromPin:(JMXInputPin *)aPin
{
    if ([aPin isKindOfClass:[JMXScriptInputPin class]]) {
        JMXScriptOutputPin *pin = (JMXScriptOutputPin *)aPin;
        if (pin.function.IsEmpty() || pin.function->IsNull() || pin.function->IsUndefined())
            return;
        Locker locker;
        HandleScope handleScope;
        Handle<Value> args[1];
        args[0] = Undefined();
        v8::Context::Scope context_scope(jsContext.ctx);
        switch (pin.type) {
            case kJMXStringPin:
            case kJMXTextPin:
            case kJMXCodePin:
                args[0] = v8::String::New([(NSString *)data UTF8String]);
                break;
            case kJMXNumberPin:
                args[0] = v8::Number::New([(NSNumber *)data doubleValue]);
                break;
            case kJMXImagePin:
                args[0] = [[JMXImageData imageDataWithImage:(CIImage *)data rect:[(CIImage *)data extent]] jsObj];
                break;
            case kJMXColorPin:
                args[0] = [(NSColor *)data jsObj];
                break;
            case kJMXSizePin:
                args[0] = [(JMXSize *)data jsObj];
                break;
            case kJMXPointPin:
                args[0] = [(JMXPoint *)data jsObj];
                break;
            default:
                // TODO - Error Message
                break;
        }
        [jsContext execFunction:pin.function withArguments:args count:1];
    } else {
        [super receiveData:data fromPin:aPin];
    }
    // XXX - base implementation doesn't do anything
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
