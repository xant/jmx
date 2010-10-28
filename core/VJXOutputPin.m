//
//  VJXOutputPin.m
//  VeeJay
//
//  Created by xant on 10/18/10.
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

#import "VJXOutputPin.h"
#import "VJXInputPin.h"
#import "VJXContext.h"

@interface VJXPin (Private)
- (void)sendData:(id)data toReceiver:(id)receiver withSelector:(NSString *)selectorName fromSender:(id)sender;
@end

@implementation VJXOutputPin
@synthesize receivers;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    self = [super initWithName:pinName
                       andType:pinType
                       ownedBy:pinOwner
                    withSignal:pinSignal
                      userData:userData
                 allowedValues:pinValues
                  initialValue:value];
    if (self) {
        receivers = [[NSMutableDictionary alloc] init];
        direction = kVJXOutputPin;
    }
    return self;
}

- (void)dealloc
{
    [receivers release];
    [super dealloc];
}

- (void)performSignal:(VJXPinSignal *)signal
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [super performSignal:signal];
    // and then propagate it to all receivers
    @synchronized (receivers) {
        for (id receiver in receivers) {
            signal.receiver = receiver;
            [self sendData:signal.data toReceiver:signal.receiver withSelector:[receivers objectForKey:receiver] fromSender:signal.sender];
        }
    }
    [pool drain];
}

- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal
{
    BOOL rv = NO;
    if ([pinReceiver respondsToSelector:NSSelectorFromString(pinSignal)]) {
        if ([[pinSignal componentsSeparatedByString:@":"] count]-1 <= 2) {
            @synchronized(receivers) {
                [receivers setObject:pinSignal forKey:pinReceiver];
            }
            rv = YES;
        } else {
            NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", pinSignal);
        }
    } else {
        NSLog(@"Object %@ doesn't respond to %@\n", pinReceiver, pinSignal);
    }
    // deliver the signal to the just connected receiver
    if (rv == YES) {
        VJXPinSignal *signal = nil;
        signal = [VJXPinSignal signalFromSender:currentSender receiver:pinReceiver data:dataBuffer[rOffset&0x1]];
        if (signal) // send the signal on-connect
            [self sendData:signal.data toReceiver:signal.receiver withSelector:pinSignal fromSender:currentSender];
    }
    return rv;
}

- (BOOL)connectToPin:(VJXInputPin *)destinationPin
{
    if ((VJXPin *)destinationPin != (VJXPin *)self && destinationPin.direction == kVJXInputPin) {
        if ([destinationPin connectToPin:self]) {
            connected = YES;
            return YES;
        }
    }
    return NO;
}

- (void)detachObject:(id)pinReceiver
{
    @synchronized(receivers) {
        [receivers removeObjectForKey:pinReceiver];
        if ([receivers count] == 0)
            connected = NO;
    }
}

- (void)disconnectFromPin:(VJXInputPin *)destinationPin
{
    [destinationPin disconnectFromPin:self];
}

- (void)disconnectAllPins
{
    NSArray *receiverObjects;
    @synchronized(receivers) {
        receiverObjects = [receivers allKeys];
        for (VJXPin *receiver in receiverObjects)
            [receiver disconnectFromPin:self];
    }
}

@end
