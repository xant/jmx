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
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    if (self = [super initWithName:pinName
                           andType:pinType
                           ownedBy:pinOwner
                        withSignal:pinSignal
                     allowedValues:pinValues
                      initialValue:value])
    {
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
        for (id receiver in receivers)
            [self sendData:signal.data toReceiver:receiver withSelector:[receivers objectForKey:receiver] fromSender:signal.sender];
    }
    [pool drain];
}

- (void)deliverData:(id)data fromSender:(id)sender
{
    // if we are an output pin and not receivers have been hooked, 
    // it's useless to perform the signal
    @synchronized(receivers) {
        if (![receivers count]) {
            // we don't have any receiver ... so we only need 
            // to set currentData and then we can return
            @synchronized(self) {
                currentData = retainData
                            ? [data retain]
                            : data;
                currentSender = sender;
            }
            return;
        }
    }
    [super deliverData:data fromSender:sender];
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
        VJXPinSignal *signal;
        @synchronized(self) {
            signal = [VJXPinSignal signalFrom:currentSender withData:currentData];
        }
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
    return rv;
}

- (void)detachObject:(id)pinReceiver
{
    @synchronized(receivers) {
        [receivers removeObjectForKey:pinReceiver];
    }
}

- (BOOL)connectToPin:(VJXInputPin *)destinationPin
{
    if ((VJXPin *)destinationPin != (VJXPin *)self) 
        return [destinationPin connectToPin:self];
    return NO;
}

- (void)disconnectFromPin:(VJXInputPin *)destinationPin
{
    return [destinationPin disconnectFromPin:self];
}

- (void)disconnectAllPins
{
    NSArray *receiverObjects;
    @synchronized(receivers) {
        receiverObjects = [receivers allKeys];
    }
    for (VJXPin *receiver in receiverObjects)
        [receiver disconnectFromPin:self];
}

@end
