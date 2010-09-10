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

@implementation VJXPin

@synthesize type, name, multiple, direction;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
     withSignal:(NSString *)pinSignal
{
    return [[[VJXPin alloc] initWithName:name andType:pinType forDirection:pinDirection ownedBy:pinOwner withSignal:pinSignal] autorelease];
}


- (id)initWithName:(NSString *)pinName andType:(VJXPinType)pinType forDirection:(VJXPinDirection)pinDirection ownedBy:(id)pinOwner withSignal:(NSString *)pinSignal
{
    if (self = [super init]) {
        type = pinType;
        name = [pinName retain];
        receivers = [[NSMutableDictionary alloc] init];
        producers = [[NSMutableArray alloc] init];
        direction = pinDirection;
        multiple = NO;
        currentData = nil;
        currentProducer = nil;
        owner = pinOwner;
        ownerSignal = pinSignal;
    }
    return self;
}

- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal
{
    BOOL rv = NO;
    id data = nil;
    id producer = nil;
    @synchronized(self) {
        if ([pinReceiver respondsToSelector:NSSelectorFromString(pinSignal)]) {
            if ([[pinSignal componentsSeparatedByString:@":"] count]-1 <= 2) {
                [receivers setObject:pinSignal forKey:pinReceiver];
                rv = YES;
                //data = [currentData retain];
                //producer = [currentProducer retain];
            } else {
                NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", pinSignal);
            }
        } else {
            NSLog(@"Object %@ doesn't respond to %@\n", pinReceiver, pinSignal);
        }
        
    }
    // deliver the signal to the just connected receiver
    /*if (rv == YES && data) {
        [self deliverSignal:data fromSender:producer ? producer : self];
        [data release];
        if (producer)
            [producer release];
    }*/
    return rv;
}

- (void)detachObject:(id)pinReceiver
{
    [receivers removeObjectForKey:pinReceiver];
}

- (void)deliverSignal:(id)data
{
    [self deliverSignal:data fromSender:self];
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
            [receiver performSelector:selector];
            break;
        case 1:
            // some other listeners could be interested only in the data,
            // regardless of the sender
            [receiver performSelector:selector withObject:data];
            break;
        case 2:
            // and finally there can be listeners which require to know also who has sent the data
            [receiver performSelector:selector withObject:data withObject:sender];
            break;
        default:
            NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", selectorName);
    }
}

- (void)deliverSignal:(id)data fromSender:(id)sender
{
    id signalData = [NSNull null];
    switch (type) {
        case kVJXStringPin:
            if ([data isKindOfClass:[NSString class]])
                signalData = data;
            break;
        case kVJXNumberPin:
            if ([data isKindOfClass:[NSNumber class]])
                signalData = data;
            break;
        case kVJXImagePin:
            if ([data isKindOfClass:[CIImage class]])
                signalData = data;
            break;
        case kVJXSizePin:
            if ([data isKindOfClass:[VJXSize class]])
                signalData = data;
            break;
        case kVJXPointPin:
            if ([data isKindOfClass:[VJXPoint class]])
                signalData = data;
            break;
        default:
            NSLog(@"Unkown pin type!\n");
    }
    @synchronized(self) {
        // save current data
        if (currentData)
            [currentData release];
        if (currentProducer)
            [currentProducer release];
        currentData = [signalData retain];
        //currentProducer = [sender retain];
        // send the signal to our owner 
        // (if we are an input pin and if our ownerregistered a selector)
        if (direction == kVJXInputPin && owner && ownerSignal)
            [self sendData:data toReceiver:owner withSelector:ownerSignal fromSender:sender];

        // and then propagate it to all receivers
        for (id receiver in receivers)
            [self sendData:data toReceiver:receiver withSelector:[receivers objectForKey:receiver] fromSender:sender];
    }
}

- (void)allowMultipleConnections:(BOOL)choice
{
    multiple = choice;
}

- (void)dealloc
{
    [name release];
    [receivers release];
    [producers release];
    if (currentData)
        [currentData release];
    if (currentProducer)
        [currentProducer release];
    [super dealloc];
}

- (BOOL)connectToPin:(VJXPin *)destinationPin
{
    @synchronized(self) {
        if (destinationPin.type == type) {
            if (direction == kVJXInputPin) {
                if (destinationPin.direction != kVJXInputPin) {
                    if ([producers count] && !multiple)
                        [self disconnectAllPins];
                    if ([destinationPin attachObject:self withSelector:@"deliverSignal:fromSender:"]) {
                        [producers addObject:destinationPin];
                        return YES;
                    }
                }
            } else if (destinationPin.direction == kVJXInputPin) {
                if (direction != kVJXInputPin) 
                    return [destinationPin connectToPin:self];
            } else if (direction == kVJXAnyPin) {
                if ([producers count] && multiple)
                    [self disconnectAllPins];
                if ([destinationPin attachObject:self withSelector:@"deliverSignal:fromSender:"]) {
                    [producers addObject:self];
                    return YES;
                }
            } else if (destinationPin.direction == kVJXAnyPin) {
                return [destinationPin connectToPin:self];
            }
            
        }
    }
    return NO;
}

- (void)disconnectFromPin:(VJXPin *)destinationPin
{
    @synchronized(self) {
        if (direction == kVJXInputPin) {
            [destinationPin detachObject:self];
            [producers removeObjectIdenticalTo:destinationPin];
        } else {
            [destinationPin disconnectFromPin:self];
        }
    }
}

- (void)disconnectAllPins
{
    while ([producers count])
        [self disconnectFromPin:[producers objectAtIndex:0]];
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (id)readPinValue
{
    id data;
    @synchronized(self) {
        data = [currentData retain];
    }
    return [data autorelease];
}

@end
