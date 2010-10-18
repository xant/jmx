//
//  VJXOutputPin.m
//  VeeJay
//
//  Created by xant on 10/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXOutputPin.h"
#import "VJXContext.h"

@implementation VJXOutputPin
@synthesize receivers;

- (id)init {
    if (self = [super init]) {
        receivers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [receivers release];
    [super dealloc];
}

- (void)deliverSignal:(id)data
{
    [self deliverSignal:data fromSender:self];
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

- (void)deliverSignal:(id)data fromSender:(id)sender
{
    // if we are an output pin and not receivers have been hooked, 
    // it's useless to perform the signal
    @synchronized(receivers) {
        if (![receivers count])
            return;
    }
    [super deliverSignal:data fromSender:sender];
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
