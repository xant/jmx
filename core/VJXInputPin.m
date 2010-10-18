//
//  VJXInputPin.m
//  VeeJay
//
//  Created by xant on 10/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXInputPin.h"


@implementation VJXInputPin

@synthesize producers;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
      forDirection:(VJXPinDirection)pinDirection
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    if (self = [super initWithName:pinName
                           andType:pinType
                      forDirection:pinDirection
                           ownedBy:pinOwner
                        withSignal:pinSignal
                     allowedValues:pinValues
                      initialValue:value])
    {
        producers = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [producers release];
    [super dealloc];
}

- (NSArray *)readProducers
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    @synchronized(producers) {
        for (VJXOutputPin *producer in producers) {
            id value = [producer readPinValue];
            if (value)
                [array addObject:value];
        }
    }
    return [array autorelease];
}

- (BOOL)moveProducerFromIndex:(NSUInteger)src toIndex:(NSUInteger)dst
{
    @synchronized(producers) {
        if ([producers count] > dst) {
            VJXOutputPin *obj = [[producers objectAtIndex:src] retain];
            [producers removeObjectAtIndex:src];
            [producers insertObject:obj atIndex:dst];
            [obj release];
            return YES;
        }
    }
    return NO;
}

- (BOOL)connectToPin:(VJXOutputPin *)destinationPin
{
    if (self.type == destinationPin.type) {
        @synchronized(producers) {
            if ([producers count] && !multiple) {
                if (direction == kVJXInputPin) {
                    [[producers objectAtIndex:0] detachObject:self];
                    [producers removeObjectAtIndex:0];
                } else {
                    [[producers objectAtIndex:0] disconnectFromPin:self];
                }
            }
            if ([destinationPin attachObject:self withSelector:@"deliverSignal:fromSender:"]) {
                [producers addObject:destinationPin];
                return YES;
            }
        }
    }
    return NO;
}

- (void)disconnectFromPin:(VJXOutputPin *)destinationPin
{
    @synchronized(producers) {
        [destinationPin detachObject:self];
        [producers removeObjectIdenticalTo:destinationPin];
    }
}

- (void)disconnectAllPins
{
    @synchronized(producers) {
        while ([producers count])
            [self disconnectFromPin:[producers objectAtIndex:0]];
    }
}

@end
