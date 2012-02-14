//
//  JMXScriptPinWrapper.m
//  JMX
//
//  Created by Andrea Guzzo on 2/1/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXScriptPinWrapper.h"
#import "JMXScriptEntity.h"
#import "JMXPin.h"
#import "JMXPinSignal.h"
#import "JMXSize.h"
#import "JMXPoint.h"
#import "NSColor+V8.h"
#import "JMXImageData.h"

@implementation JMXScriptPinWrapper

+ (id)pinWrapperWithName:(NSString *)name
                function:(v8::Persistent<v8::Function>) aFunction
            scriptEntity:(JMXScriptEntity *)entity
{
    return [[[self alloc] initWithName:name
                              function:aFunction
                          scriptEntity:entity] autorelease];
}

+ (id)pinWrapperWithName:(NSString *)name
              statements:(NSString *)statements
            scriptEntity:(JMXScriptEntity *)entity
{
    return [[[self alloc] initWithName:name
                            statements:statements
                          scriptEntity:entity] autorelease];
}

- (id)initWithName:(NSString *)name
          function:(v8::Persistent<v8::Function>) aFunction
      scriptEntity:(JMXScriptEntity *)entity
{
    self = [super initWithName:name];
    if (self) {
        function = aFunction;
        scriptEntity = entity; // weak
    }
    return self;
}

- (id)initWithName:(NSString *)name
        statements:(NSString *)jsStatements
      scriptEntity:(JMXScriptEntity *)entity
{
    self = [super initWithName:name];
    if (self) {
        statements = [jsStatements copy];
        scriptEntity = entity; // weak
    }
    return self;
}

- (void)dealloc
{
    [statements release];
    [virtualPin dealloc];
    [super dealloc];
}

- (void)performSignal:(JMXPinSignal *)signal
{
    
}

- (void)propagateSignal:(id)data
{
    /*
    kJMXVoidPin =    (0),
    kJMXStringPin =  (1),
    kJMXTextPin =    (1<<1),
    kJMXCodePin =    (1<<2),
    kJMXNumberPin =  (1<<3),
    kJMXImagePin =   (1<<4),
    kJMXAudioPin =   (1<<5),
    kJMXPointPin =   (1<<6),
    kJMXSizePin =    (1<<7),
    kJMXRectPin =    (1<<8),
    kJMXColorPin =   (1<<9),
    kJMXBooleanPin = (1<<10)
    */
    Locker locker;
    HandleScope handleScope;
    v8::Context::Scope context_scope(scriptEntity.jsContext.ctx);

    Handle<Value> args[1];
    switch (virtualPin.type) {
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
            break;
    }
    if (!function.IsEmpty() && !function->IsNull())
        [scriptEntity.jsContext execFunction:function withArguments:args count:1];
    else if (statements)
        [scriptEntity.jsContext execCode:statements];
}

- (void)receivedSignal:(id)data
{
    [self performSelector:@selector(propagateSignal:)
                 onThread:scriptEntity.executionThread
               withObject:(id)data
            waitUntilDone:(BOOL)NO];
}

- (void)connectToPin:(JMXPin *)pin
{
    [virtualPin disconnectAllPins];
    [virtualPin release];
    
    if (pin.direction == kJMXOutputPin) {
        virtualPin = [JMXPin pinWithLabel:@"jsReceiver"
                                       andType:pin.type
                                  forDirection:kJMXInputPin
                                       ownedBy:self
                                    withSignal:@"receivedSignal:"];
        [pin connectToPin:virtualPin];
    } else {
        virtualPin = [JMXPin pinWithLabel:@"jsProducer"
                                  andType:pin.type
                             forDirection:kJMXOutputPin
                                  ownedBy:self
                               withSignal:@"performSignal:"];
    }
    [pin connectToPin:virtualPin];
}


- (void)disconnect
{
    [virtualPin disconnectAllPins];
}
@end
