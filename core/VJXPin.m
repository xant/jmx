//
//  VJXConnector.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXPin.h"
#import "VJXContext.h"
#import "VJXOutputPin.h"
#import "VJXInputPin.h"

@implementation VJXPinSignal

@synthesize sender, data;

+ (id)signalFrom:(id)sender withData:(id)data
{
    id signal = [VJXPinSignal alloc];
    if (signal) {
        return [[signal initWithSender:sender andData:data] autorelease];
    }
    return nil;
}

- (id)initWithSender:(id)theSender andData:(id)theData
{
    if (self = [super init]) {
        self.sender = theSender;
        self.data = theData;
    }
    return self;
}

- (void)dealloc
{
    self.sender = nil;
    self.data = nil;
    [super dealloc];
}

@end

@implementation VJXPin

@synthesize type, name, multiple, continuous, buffered, retainData, 
            direction, allowedValues, owner, minValue, maxValue;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
    allowedValues:(NSArray *)pinValues
     initialValue:(id)value
    
{
    return [[[[self class] alloc] initWithName:name
                                       andType:pinType
                                  forDirection:pinDirection
                                       ownedBy:pinOwner withSignal:pinSignal
                                 allowedValues:pinValues
                                  initialValue:value]
            autorelease];
}

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
     withSignal:(NSString *)pinSignal
  allowedValues:(NSArray *)pinValues
{
    return  [[self class] pinWithName:name
                              andType:pinType
                         forDirection:pinDirection
                              ownedBy:pinOwner
                           withSignal:pinSignal
                        allowedValues:pinValues
                         initialValue:nil];
}

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
{
    return [[self class] pinWithName:name
                       andType:pinType
                  forDirection:pinDirection
                       ownedBy:pinOwner
                    withSignal:pinSignal
                 allowedValues:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
      forDirection:(VJXPinDirection)pinDirection
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
{
    return [self initWithName:name
                      andType:pinType
                 forDirection:pinDirection
                      ownedBy:pinOwner
                   withSignal:pinSignal
                allowedValues:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
      forDirection:(VJXPinDirection)pinDirection
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
     allowedValues:(NSArray *)pinValues
{
    return [self initWithName:pinName
                      andType:pinType
                 forDirection:pinDirection
                      ownedBy:pinOwner
                   withSignal:pinSignal
                allowedValues:pinValues
                 initialValue:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
      forDirection:(VJXPinDirection)pinDirection
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    if (self = [super init]) {
        type = pinType;
        name = [pinName retain];
        direction = pinDirection;
        multiple = NO;
        continuous = YES;
        retainData = YES;
        buffered = NO;
        currentData = nil;
        currentSender = nil;
        owner = pinOwner;
        ownerSignal = pinSignal;
        if (pinValues)
            allowedValues = [[NSMutableArray arrayWithArray:pinValues] retain];
        if (value && [self isCorrectDataType:value]) {
            currentData = [value retain];
            currentSender = owner;
        }
    }
    return self;
}

- (id)init
{
    // bad usage
    [self dealloc];
    return nil;
}

- (void)performSignal:(VJXPinSignal *)signal
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // send the signal to our owner 
    // (if we are an input pin and if our owner registered a selector)
    if (direction == kVJXInputPin && owner && ownerSignal)
        [self sendData:signal.data toReceiver:owner withSelector:ownerSignal fromSender:signal.sender];
    [pool drain];
}

- (BOOL)isCorrectDataType:(id)data
{
    switch (type) {
        case kVJXStringPin:
            if (![data isKindOfClass:[NSString class]])
                return NO;
            break;
        case kVJXNumberPin:
            if (![data isKindOfClass:[NSNumber class]])
                return NO;
            break;
        case kVJXImagePin:
            if (![data isKindOfClass:[CIImage class]])
                return NO;
            break;
        case kVJXSizePin:
            if (![data isKindOfClass:[VJXSize class]])
                return NO;
            break;
        case kVJXPointPin:
            if (![data isKindOfClass:[VJXPoint class]])
                return NO;
            break;
        case kVJXAudioPin:
            if (![data isKindOfClass:[VJXAudioBuffer class]])
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
    if (currentData)
        [currentData release];
    [name release];
    if (allowedValues)
        [allowedValues release];
    [super dealloc];
}

- (BOOL)connectToPin:(VJXPin *)destinationPin
{
    if (direction == kVJXOutputPin && destinationPin.direction == kVJXInputPin) {
        return [(VJXOutputPin *)self connectToPin:(VJXInputPin *)destinationPin];
    } else if (direction == kVJXInputPin && destinationPin.direction == kVJXOutputPin) {
        return [(VJXOutputPin *)destinationPin connectToPin:(VJXInputPin *)self];
    }
    return NO;
}

- (void)disconnectFromPin:(VJXPin *)destinationPin
{
}

- (void)disconnectAllPins
{

}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

+ (NSString *)nameforType:(VJXPinType)aType
{
    switch (aType) {
        case kVJXStringPin:
            return @"String";
            break;
        case kVJXNumberPin:
            return @"Number";
            break;
        case kVJXImagePin:
            return @"Image";
            break;
        case kVJXSizePin:
            return @"Size";
            break;
        case kVJXPointPin:
            return @"Point";
            break;
        case kVJXAudioPin:
            return @"Audio";
            break;
    }
    return nil;
}

- (NSString *)typeName
{
    NSString *aName = [VJXPin nameforType:type];
    if (aName)
        return aName;
    return @"Unknown";
}

- (NSString *)description
{
    NSString *ownerName;
    if ([owner respondsToSelector:@selector(name)])
        ownerName = [owner performSelector:@selector(name)];
    return [NSString stringWithFormat:@"%@:%@", ownerName, name];
}

- (void)setRetainData:(BOOL)doRetain
{
    @synchronized(self) {
        if (retainData && !doRetain) {
            if (currentData)
                [currentData release];
        } else if (!retainData && doRetain) {
            if (currentData)
                [currentData retain];
        }
        retainData = doRetain;
    }
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

- (void)addMinLimit:(id)value
{
    if ([self isCorrectDataType:minValue])
        minValue = [value retain];
    
}

- (void)addMaxLimit:(id)value
{
    if ([self isCorrectDataType:maxValue])
        maxValue = [value retain];
}

- (id)readPinValue
{
    id data;
    @synchronized(self) {
        data = [currentData retain];
    }
    return [data autorelease];
}

- (void)deliverSignal:(id)data fromSender:(id)sender
{
    // check if NULL data has been signaled
    // and if it's the case, clear currentData and return
    if (!data) {
        @synchronized(self) {
            if (currentData)
                [currentData release];
            currentData = nil;
        }
        return;
    }
    // if instead new data arrived, check if it's of the correct type
    // and propagate the signal if that's the case
    if ([self isCorrectDataType:data]) {
        @synchronized(self) {
            if (data) {
                // check if we restrict possible values
                if (allowedValues && ![allowedValues containsObject:data]) {
                    // TODO - Error Message (a not allowed value has been signaled
                    return;
                }
                if (currentData) {
                    if (!continuous && [currentData isEqual:data])
                        return;
                    if (retainData)
                        [currentData release];
                }
                currentData = retainData
                ? [data retain]
                : data;
            }
            if (sender)
                currentSender = sender;
            else
                currentSender = self;
        }
        VJXPinSignal *signal = [VJXPinSignal signalFrom:sender withData:data];
        
#if USE_NSOPERATIONS
        NSBlockOperation *signalDelivery = [NSBlockOperation blockOperationWithBlock:^{
            [self performSignal:signal];
        }];
        [signalDelivery setQueuePriority:NSOperationQueuePriorityVeryHigh];
        [signalDelivery setThreadPriority:1.0];
        [[VJXContext operationQueue] addOperation:signalDelivery];
#else
        [self performSelector:@selector(performSignal:) onThread:[VJXContext signalThread] withObject:signal waitUntilDone:NO];
#endif
    }
}

- (void)sendData:(id)data toReceiver:(id)receiver withSelector:(NSString *)selectorName fromSender:(id)sender
{
    SEL selector = NSSelectorFromString(selectorName);
    int selectorArgsNum = [[selectorName componentsSeparatedByString:@":"] count]-1;
    // checks are now done when registering receivers
    // so we can avoid checking again now if receiver responds to selector and 
    // if the selector expects the correct amount of arguments.
    // this routine is expected to deliver the signals as soon as possible
    // all safety checks must be done before putting new objects in the receivers' table
    switch (selectorArgsNum) {
        case 0:
            // some listener could be uninterested to the data, 
            // but just want to get notified when something travels on a pin
            [receiver performSelector:selector withObject:nil];
            break;
        case 1:
            // some other listeners could be interested only in the data,
            // regardless of the sender
            [receiver performSelector:selector withObject:data];
            break;
        case 2:
            [receiver performSelector:selector withObject:data withObject:sender];
            break;
        default:
            NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", selectorName);
    }
}

@end
