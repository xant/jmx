//
//  JMXConnector.m
//  JMX
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#define __JMXV8__
#import "JMXPin.h"
#import "JMXContext.h"
#import "JMXOutputPin.h"
#import "JMXInputPin.h"
#import "JMXScript.h"
#import "JMXEntity.h"
#import "JMXScriptEntity.h"
#import "JMXScriptPinWrapper.h"
#import "JMXByteArray.h"
#import <libkern/OSAtomic.h>
using namespace v8;

@implementation JMXPin

@synthesize type, label, multiple, continuous, connected, sendNotifications,
            direction, allowedValues, minValue, maxValue, connections, owner, mode;

#pragma mark Constructors

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)pinValues
     initialValue:(id)value

{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [[[pinClass alloc] initWithLabel:label
                                    andType:pinType
                                    ownedBy:pinOwner
                                 withSignal:pinSignal
                                   userData:userData
                              allowedValues:pinValues
                               initialValue:value]
            autorelease];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
     withSignal:(NSString *)pinSignal
     userData:(id)userData
  allowedValues:(NSArray *)pinValues
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return  [pinClass pinWithLabel:label
                              andType:pinType
                         forDirection:pinDirection
                              ownedBy:pinOwner
                           withSignal:pinSignal
                             userData:userData
                        allowedValues:pinValues
                         initialValue:nil];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [pinClass pinWithLabel:label
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:nil
                   allowedValues:nil];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [pinClass pinWithLabel:label
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:userData
                   allowedValues:nil];
}

#pragma mark Initializers

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:nil
                allowedValues:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:pinValues
                 initialValue:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    self = [super initWithName:@"JMXPin"];
    if (self) {
        type = pinType;
        label = [pinLabel copy];
        multiple = NO;
        continuous = YES;
        connected = NO;
        currentSender = nil;
        owner = pinOwner;
        ownerSignal = [pinSignal copy];
        ownerUserData = userData;
        readMode = kJMXPinReadModeInternal;
        
        // check if we should use a different read mode (depending on our owner capabilities)
        if (owner) {
            if (pinSignal && [self isKindOfClass:[JMXOutputPin class]]) {
                readMode = kJMXPinReadModeOwnerSelector;
                readSignal = NSSelectorFromString(pinSignal);
            } else {
                SEL signal = NSSelectorFromString(self.label);
                if ([owner respondsToSelector:signal]) {
                    readMode = kJMXPinReadModeOwnerSelector;
                    readSignal = signal;
                } else if ([owner conformsToProtocol:@protocol(JMXPinOwner)]) {
                    readMode = kJMXPinReadModeOwnerProtocol;
                }
            }
        }
        
        sendNotifications = YES;
        memset(dataBuffer, 0, sizeof(dataBuffer));
        allowedValues = pinValues ? [[NSMutableArray arrayWithArray:pinValues] retain] : nil;
        offset = 0;
        if (value && [self isCorrectDataType:value]) {
            currentSender = owner;
            dataBuffer[offset] = [value retain];
        }
        [self addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:[JMXPin nameForType:type]]];
        [self addAttribute:[NSXMLNode attributeWithName:@"multiple" stringValue:multiple ? @"YES" : @"NO" ]];
        [self addAttribute:[NSXMLNode attributeWithName:@"connected" stringValue:connected ? @"YES" : @"NO" ]];
        [self addAttribute:[NSXMLNode attributeWithName:@"label" stringValue:label]];
        connections = [[JMXElement alloc] initWithName:@"connections"];
        [self addChild:connections];
        [self performSelectorOnMainThread:@selector(notifyCreation) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (id)init
{
    // bad usage
    [self dealloc];
    return nil;
}

- (void)notifyCreation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinCreated" object:self];
}

- (void)notifyRelease
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDestroyed" object:self];
}

#pragma mark Implementation

+ (NSString *)nameForType:(JMXPinType)type
{
    switch ((int)type) {
        case kJMXStringPin:
            return @"String";
        case kJMXTextPin:
            return @"Text";
        case kJMXCodePin:
            return @"Code";
        case kJMXNumberPin:
            return @"Number";
        case kJMXImagePin:
            return @"Image";
        case kJMXSizePin:
            return @"Size";
        case kJMXRectPin:
            return @"Rect";
        case kJMXPointPin:
            return @"Point";
        case kJMXAudioPin:
            return @"Audio";
        case kJMXColorPin:
            return @"Color";
        case kJMXBooleanPin:
            return @"Boolean";
        case kJMXByteArrayPin:
            return @"ByteArray";
        case kJMXDictionaryPin:
            return @"Dictionary";
    }
    return nil;
}

+ (NSString *)nameForMode:(JMXPinMode)mode
{
    switch ((int)mode) {
        case kJMXPinModeAuto:
            return @"Auto";
        case kJMXPinModeActive:
            return @"Active";
        case kJMXPinModePassive:
            return @"Passive";
    }
    return nil;
}

- (BOOL)isCorrectDataType:(id)data
{
    switch (type) {
        // NOTE: String, Text and Code and up being mapped against the same datatype
        //       (NSString) so it's safe to allow connections among pins of those types 
        case kJMXStringPin:
        case kJMXTextPin:
        case kJMXCodePin:
            if (![data isKindOfClass:[NSString class]])
                return NO;
            break;
        case kJMXBooleanPin:
            if ([[data className] isEqualToString:@"NSCFBoolean"] || [data isKindOfClass:[NSNumber class]])
                return YES;
            return NO;
            break;
        case kJMXNumberPin:
            if ([[data className] isEqualToString:@"NSCFNumber"] || [data isKindOfClass:[NSNumber class]])
                return YES;
            return NO;
            break;
        case kJMXImagePin:
            if (![data isKindOfClass:[CIImage class]])
                return NO;
            break;
        case kJMXByteArrayPin:
            if (![data isKindOfClass:[JMXByteArray class]])
                return NO;
            break;
        case kJMXDictionaryPin:
            if (![data isKindOfClass:[NSDictionary class]])
                return NO;
            break;
        case kJMXSizePin:
            if (![data isKindOfClass:[JMXSize class]])
                return NO;
            break;
        case kJMXRectPin:
            if (![data isKindOfClass:[JMXRect class]])
                return NO;
            break;
        case kJMXPointPin:
            if (![data isKindOfClass:[JMXPoint class]])
                return NO;
            break;
        case kJMXAudioPin:
            if (![data isKindOfClass:[JMXAudioBuffer class]])
                return NO;
            break;
        case kJMXColorPin:
            if (![data isKindOfClass:[NSColor class]])
                return NO;
            break;
        case kJMXVoidPin:
            if ((id)data != [NSNull null])
                return NO;
            break;
        default:
            NSLog(@"Unknown pin type!\n");
            return NO;
    }
    return YES;
}

- (void)allowMultipleConnections:(BOOL)choice
{
    multiple = choice;
}

- (void)dealloc
{
    @synchronized(self) {
        [self performSelectorOnMainThread:@selector(notifyRelease) withObject:nil waitUntilDone:YES];
    }
    [connections detach];
    [connections release];
    [label release];
    if (allowedValues)
        [allowedValues release];
    for (int i = 0; i < kJMXPinDataBufferMask+1; i++)
        [dataBuffer[i] release];
    [super dealloc];
}

- (BOOL)connectToPin:(JMXPin *)destinationPin
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];

    NSBlockOperation *notification = [NSBlockOperation blockOperationWithBlock:^{
        // send a connect notification for all involved pins
        if (self.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                                object:self
                                                              userInfo:userInfo];
        }
        if (destinationPin.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                                object:destinationPin
                                                              userInfo:userInfo];
        }
    }];
    [notification setQueuePriority:NSOperationQueuePriorityVeryHigh];
    if (![[NSThread currentThread] isMainThread]) {
        [[NSOperationQueue mainQueue] addOperations:[NSArray arrayWithObject:notification]
                                  waitUntilFinished:YES];
    } else {
        [notification start];
        [notification waitUntilFinished];
    }

    
    return YES;
}

- (void)disconnectFromPin:(JMXPin *)destinationPin
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
    
    NSBlockOperation *notification = [NSBlockOperation blockOperationWithBlock:^{
        // send a disconnect notification for all the involved pins
        if (self.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                                object:self
                                                              userInfo:userInfo];
        }
        if (destinationPin.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                                object:destinationPin
                                                              userInfo:userInfo];
        }
    }];
    [notification setQueuePriority:NSOperationQueuePriorityVeryHigh];
    if (![[NSThread currentThread] isMainThread]) {
        [[NSOperationQueue mainQueue] addOperations:[NSArray arrayWithObject:notification]
                                  waitUntilFinished:YES];
    } else {
        [notification start];
        [notification waitUntilFinished];
    }
}

- (void)disconnectAllPins
{

}

- (NSString *)typeName
{
    NSString *aName = [JMXPin nameForType:type];
    if (aName)
        return aName;
    return @"Unknown";
}

- (NSString *)modeName
{
    NSString *aName = [JMXPin nameForMode:mode];
    if (aName)
        return aName;
    return @"Unknown";
}

- (NSString *)description
{
    NSString *ownerName;
    if ([owner respondsToSelector:@selector(name)])
        ownerName = [owner performSelector:@selector(name)];
    return [NSString stringWithFormat:@"%@:%@", ownerName, label];
}

- (void)addAllowedValue:(id)value
{
    if ([self isCorrectDataType:value]) {
        if (!allowedValues)
            allowedValues = [[NSMutableArray alloc] init];
        [allowedValues addObject:value];
    }
}

- (void)addAllowedValues:(NSArray *)values
{
    for (id value in values)
        [self addAllowedValue:value];
}

- (void)removeAllowedValue:(id)value
{
    if ([self isCorrectDataType:value] && allowedValues) {
        [allowedValues removeObject:value];
        if ([allowedValues count] == 0) {
            [allowedValues release];
            allowedValues = nil;
        }
    }
}

- (void)removeAllowedValues:(NSArray *)values
{
    for (id value in values)
        [self removeAllowedValue:value];
}

- (void)setMinLimit:(id)value
{
    if ([self isCorrectDataType:value])
        minValue = [value retain];
}

- (void)setMaxLimit:(id)value
{
    if ([self isCorrectDataType:value])
        maxValue = [value retain];
}

- (id)readData
{
    // if we have an owner which conforms to the <JMXPinOwner> protocol
    // we will send it a message to get the actual value
    id 
    ret = nil;
    
    switch (readMode) {
        case kJMXPinReadModeOwnerSelector:
            if (self.type == kJMXBooleanPin) {
                BOOL raw;
                // edge case for boolean type
                NSInvocation *invocation = [NSInvocation 
                                            invocationWithMethodSignature:[owner methodSignatureForSelector:readSignal]];
                [invocation setTarget:owner];
                [invocation setSelector:readSignal];
                [invocation invokeWithTarget:owner];
                [invocation getReturnValue:(void *)&raw];
                ret = [NSNumber numberWithBool:raw];
            } else {
                ret = [owner performSelector:readSignal];
            }
            break;
        case kJMXPinReadModeOwnerProtocol:
            ret = [owner provideDataToPin:self];
            break;
        default:
            break;
    }
    
    // failback always to kJMXPinReadModeInternal if we got no data in other ways
    if (!ret) {
        // otherwise we will return the last signaled data
        ret = [[dataBuffer[offset&kJMXPinDataBufferMask] retain] autorelease];
    }
    return ret;
}

- (void)deliverData:(id)data
{
    [self deliverData:data fromSender:self];
}

- (void)sendData:(id)data toReceiver:(id)receiver withSelector:(NSString *)selectorName fromSender:(id)sender
{
    SEL selector = NSSelectorFromString(selectorName);
    [receiver performSelector:selector withObject:data withObject:ownerUserData];
}

- (BOOL)isValidData:(id)data
{
    if(![self isCorrectDataType:data])
        return NO;
    // check if we restrict possible values
    if (allowedValues && ![allowedValues containsObject:data]) {
        // TODO - Error Message (a not allowed value has been signaled
        return NO;
    }
    /* TODO - validate the actual value */
    switch ((int)self.type) {
        case kJMXNumberPin:
            break;
        case kJMXStringPin:
            break;
        case kJMXSizePin:
            break;
        case kJMXRectPin:
            break;
        case kJMXPointPin:
            break;
        case kJMXByteArrayPin:
            break;
        case kJMXDictionaryPin:
            break;
            
    }
    return YES;
}

- (void)deliverData:(id)data fromSender:(id)sender
{

    // check if NULL data has been signaled
    // and if it's the case, clear currentData and return
    if (!data) {
        return;
    }
    // if instead new data arrived, check if it's of the correct type
    // and propagate the signal if that's the case
    if ([self isValidData:data]) {
        id toRelease = nil;
        UInt32 nextOffset = (offset+1)&kJMXPinDataBufferMask;
        toRelease = dataBuffer[nextOffset];
        dataBuffer[nextOffset] = [data retain];
        OSAtomicIncrement32(&offset);
        [toRelease release];
        if (sender)
            currentSender = sender;
        else
            currentSender = self;
        JMXPinSignal *signal;

        @synchronized(self) {
            if (owner)
                signal = [JMXPinSignal signalFromSender:sender receiver:owner data:data];
        }

#if USE_NSOPERATIONS
        NSBlockOperation *signalDelivery = [NSBlockOperation blockOperationWithBlock:^{
            [self performSignal:signal];
        }];
        [signalDelivery setQueuePriority:NSOperationQueuePriorityVeryHigh];
        //[signalDelivery setThreadPriority:1.0];
        [[JMXContext operationQueue] addOperation:signalDelivery];
#else
        [self performSelector:@selector(performSignal:)
                     onThread:[JMXContext signalThread]
                   withObject:signal
                waitUntilDone:NO];
#endif
    }
}

- (void)performSignal:(JMXPinSignal *)signal
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // send the signal to our owner
    // (if we are an input pin and if our owner registered a selector)
    if (direction == kJMXInputPin) {
        if (owner) {
            if (ownerSignal && [owner respondsToSelector:NSSelectorFromString(ownerSignal)])
                [self sendData:signal.data toReceiver:signal.receiver withSelector:ownerSignal fromSender:signal.sender];
            else if ([owner conformsToProtocol:@protocol(JMXPinOwner)])
                [owner performSelector:@selector(receiveData:fromPin:) withObject:signal.data withObject:self];
    
        }
    }
    [pool drain];
}

- (BOOL)canConnectToPin:(JMXPin *)pin
{
    JMXPinType pinType = pin.type;
    int check = kJMXTextPin|kJMXCodePin|kJMXTextPin;
    BOOL typeCheck = (((type&check && pinType&check) || type == pinType) && direction != pin.direction) ? YES : NO;
    BOOL modeCheck = ((pin.mode == kJMXPinModeAuto || self.mode == kJMXPinModeAuto) || 
                      (pin.mode == kJMXPinModeActive && self.mode == kJMXPinModePassive) ||
                      (pin.mode == kJMXPinModePassive && self.mode == kJMXPinModeActive))
                    ? YES : NO;
    return (typeCheck && modeCheck) ? YES : NO;
}

- (id)data
{
    return [self readData];
}

- (void)setData:(id)data
{
    [self deliverData:data fromSender:self];
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/library/mac/#documentation/cocoa/Reference/Foundation/Protocols/NSCopying_Protocol/Reference/Reference.html#//apple_ref/occ/intf/NSCopying
    return [self retain];
}

- (void)detach
{
    @synchronized(self) {
        owner = nil;
        if (ownerSignal)
            [ownerSignal release];
        ownerSignal = nil;
    }
    [super detach];
}

#pragma mark V8

static v8::Handle<Value>direction(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXPin *pin = (JMXPin *)info.Holder()->GetAlignedPointerFromInternalField(0);
    v8::Handle<String> ret = String::New((pin.direction == kJMXInputPin) ? "input" : "output");
    return handle_scope.Close(ret);
}

static v8::Handle<Value>type(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXPin *pin = (JMXPin *)info.Holder()->GetAlignedPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *typeName = [pin typeName];
    v8::Handle<String> ret = String::New([typeName UTF8String], [typeName length]);
    [pool drain];
    return handle_scope.Close(ret);
}

static v8::Handle<Value>mode(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXPin *pin = (JMXPin *)info.Holder()->GetAlignedPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *modeName = [pin modeName];
    v8::Handle<String> ret = String::New([modeName UTF8String], [modeName length]);
    [pool drain];
    return handle_scope.Close(ret);
}

static v8::Handle<Value>connect(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXPin *pin = (JMXPin *)args.Holder()->GetAlignedPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (args[0]->IsFunction()) {
        v8::Local<Context> globalContext = v8::Context::GetCalling();
        JMXScript *ctx = [JMXScript getContext];
        JMXScriptPinWrapper *wrapper = nil;
        {
            v8::Unlocker unlocker;
            wrapper = [ctx.scriptEntity wrapPin:pin
                                                        withFunction:Persistent<Function>::New(Handle<Function>::Cast(args[0]))];
            [pool release];
        }
        if (wrapper)
            return  handleScope.Close([wrapper jsObj]);
    } else if (args[0]->IsObject()) {
        String::Utf8Value str(args[0]->ToString());
        if (strcmp(*str, "[object Pin]") == 0) {
            v8::Handle<Object> object = args[0]->ToObject();
            JMXPin *dest = (JMXPin *)object->GetAlignedPointerFromInternalField(0);
            if (dest) {
                {
                    v8::Unlocker unlocker;
                    BOOL ret = [pin connectToPin:dest];
                }
                [pool release];
                return handleScope.Close([dest jsObj]);
            }
        } else {
            NSLog(@"Pin::connect(): Bad param %s (should have been a Pin object)", *str);
        }
    } else {
        NSLog(@"Pin::connect(): argument is not an object");
    }
    [pool release];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value>disconnectAll(const Arguments& args)
{   
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    JMXPin *pin = (JMXPin *)args.Holder()->GetAlignedPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    {
        Unlocker unlocker;
        [pin disconnectAllPins];
    }
    [pool release];
    return Undefined();
}

static v8::Handle<Value>disconnect(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    JMXPin *pin = (JMXPin *)args.Holder()->GetAlignedPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (args[0]->IsObject()) {
        String::Utf8Value str(args[0]->ToString());
        if (strcmp(*str, "[object Pin]") == 0) {
            v8::Handle<Object> object = args[0]->ToObject();
            id dest = (id)object->GetAlignedPointerFromInternalField(0);
            if (dest) {
                Unlocker unlocker;
                ret = YES;
                if ([dest isKindOfClass:[JMXPin class]])
                    [pin disconnectFromPin:dest];
                else if ([dest isKindOfClass:[JMXScriptPinWrapper class]])
                    [dest disconnect];
                else
                    ret = NO;
            }
        } else {
            NSLog(@"Pin::connect(): Bad param %s (should have been a Pin object)", *str);
        }
    } else {
        NSLog(@"Pin::connect(): argument is not an object");
    }
    [pool release];
    return handleScope.Close(v8::Boolean::New(ret));

}

static v8::Handle<Value>exportToBoard(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope scope;
    BOOL ret = NO;
    JMXPin *pin = (JMXPin *)args.Holder()->GetAlignedPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *label = nil;
    if (!arg.IsEmpty()) {
        v8::String::Utf8Value value(args[0]);
        label = [NSString stringWithUTF8String:*value];
    }
    v8::Local<Context> globalContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext];
    if (ctx && ctx.scriptEntity) {        
        if (pin.direction == kJMXInputPin)
            [ctx.scriptEntity proxyInputPin:(JMXInputPin *)pin withLabel:label];
        else 
            [ctx.scriptEntity proxyOutputPin:(JMXOutputPin *)pin withLabel:label];
        ret = YES;
    }
    [pool release];
    return scope.Close(v8::Boolean::New(ret));
}

static void SetData(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value nameStr(name);
    JMXPin *obj = (JMXPin *)info.Holder()->GetAlignedPointerFromInternalField(0);

    id val = nil;
    if (obj.type == kJMXVoidPin) {
        val = [NSNull null];
    } else if (value->IsNumber()) {
        val = [NSNumber numberWithDouble:value->ToNumber()->NumberValue()];
    } else if (value->IsString()) {
        String::Utf8Value str(value->ToString());
        val = [NSString stringWithUTF8String:*str];
    } else if (value->IsObject()) {
        val = (id)value->ToObject()->GetAlignedPointerFromInternalField(0);
    } else {
        NSLog(@"Bad parameter (not object) passed to %s", *nameStr);
        [pool release];
        return;
    }
    
    if (val) {
        [obj setData:val];
    } else {
        // TODO - Error messages
    }
    [pool release];
}

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Pin"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("connect", FunctionTemplate::New(connect));
    classProto->Set("disconnect", FunctionTemplate::New(disconnect));
    classProto->Set("disconnectAll", FunctionTemplate::New(disconnectAll));
    classProto->Set("export", FunctionTemplate::New(exportToBoard));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("label"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("type"), type);
    instanceTemplate->SetAccessor(String::NewSymbol("mode"), mode);
    instanceTemplate->SetAccessor(String::NewSymbol("direction"), direction);
    instanceTemplate->SetAccessor(String::NewSymbol("multiple"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("continuous"), GetBoolProperty, SetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("minValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("maxValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("data"), GetObjectProperty, SetData);
    instanceTemplate->SetAccessor(String::NewSymbol("connected"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("sendNotifications"), GetBoolProperty, SetBoolProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("owner"), accessObjectProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    NSDebug(@"JMXPin objectTemplate created");
    return objectTemplate;
}

static void JMXPinJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXPin *obj = static_cast<JMXPin *>(parameter);
    NSDebug(@"V8 WeakCallback (Pin) called %@", obj);
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
    HandleScope handleScope;
    v8::Persistent<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    //v8::Persistent<Object> jsInstance = v8::Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    //jsInstance.MakeWeak([self retain], JMXPinJSDestructor);
    jsInstance->SetAlignedPointerInInternalField(0, self);
    return handleScope.Close(jsInstance);
}


@end

