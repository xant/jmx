//
//  VJXInputPin.m
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

#import "VJXInputPin.h"
#import "VJXOutputPin.h"

@implementation VJXInputPin

@synthesize producers;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    if (self = [super initWithName:pinName
                           andType:pinType
                           ownedBy:pinOwner
                        withSignal:pinSignal
                          userData:userData
                     allowedValues:pinValues
                      initialValue:value])
    {
        producers = [[NSMutableArray alloc] init];
        direction = kVJXInputPin;
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
            id value = [producer readData];
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
            if ([destinationPin attachObject:self withSelector:@"deliverData:fromSender:"]) {
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
