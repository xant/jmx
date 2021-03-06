//
//  JMXInputPin.m
//  JMX
//
//  Created by xant on 10/18/10.
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

#import "JMXInputPin.h"
#import "JMXOutputPin.h"
#import "JMXAttribute.h"

@interface JMXInputPin ()
{
    NSMutableArray      *producers;
    int passiveProducersCount;
    OSSpinLock producersLock;
}

@end

@implementation JMXInputPin

@synthesize producers;

- (id)initWithLabel:(NSString *)pinLabel
            andType:(JMXPinType)pinType
            ownedBy:(id)pinOwner
         withSignal:(NSString *)pinSignal
           userData:(id)userData
      allowedValues:(NSArray *)pinValues
       initialValue:(id)value
{
    self = [super initWithLabel:pinLabel
                       andType:pinType
                       ownedBy:pinOwner
                    withSignal:pinSignal
                      userData:userData
                 allowedValues:pinValues
                  initialValue:value];
    if (self) {
        producers = [[NSMutableArray alloc] init];
        direction = kJMXInputPin;
        [self addAttribute:[JMXAttribute attributeWithName:@"direction" stringValue:@"input"]];
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
    OSSpinLockLock(&producersLock);
    for (JMXOutputPin *producer in producers) {
        id value = [producer readData];
        if (value)
            [array addObject:value];
    }
    OSSpinLockUnlock(&producersLock);
    return [array autorelease];
}

- (id)readData
{
    if (passiveProducersCount) {
        JMXOutputPin *producer = [producers objectAtIndex:0];
        return [producer readData];
    } else {
        return [super readData];
    }
}

- (BOOL)moveProducerFromIndex:(NSUInteger)src toIndex:(NSUInteger)dst
{
    OSSpinLockLock(&producersLock);
    if ([producers count] > dst) {
        JMXOutputPin *obj = [[producers objectAtIndex:src] retain];
        [producers removeObjectAtIndex:src];
        [producers insertObject:obj atIndex:dst];
        [obj release];
        return YES;
    }
    OSSpinLockUnlock(&producersLock);
    return NO;
}

- (BOOL)connectToPin:(JMXOutputPin *)destinationPin
{
    if ([self canConnectToPin:destinationPin]) {
        OSSpinLockLock(&producersLock);
        if ([producers count] && !multiple) {
            JMXOutputPin *producer = [producers objectAtIndex:0];
            [producer detachObject:self];
            [super disconnectFromPin:producer];
            if (producer.mode == kJMXPinModePassive)
                passiveProducersCount--;
            [producers removeObjectAtIndex:0];
        }
        if ([destinationPin attachObject:self withSelector:@"deliverData:fromSender:"]) {
            [producers addObject:destinationPin];
            connected = YES;
            NSXMLNode *connectedAttribute = [self attributeForName:@"connected"];
            [connectedAttribute setStringValue:@"YES"];
            if (destinationPin.mode == kJMXPinModePassive)
                passiveProducersCount++;
            return [super connectToPin:destinationPin];
        }
        OSSpinLockUnlock(&producersLock);
    }
    return NO;
}

- (void)disconnectFromPin:(JMXOutputPin *)destinationPin
{
    [destinationPin retain];
    OSSpinLockLock(&producersLock);
    [producers removeObjectIdenticalTo:destinationPin];
    [destinationPin detachObject:self];
    if (destinationPin.mode == kJMXPinModePassive)
        passiveProducersCount--;
    if ([producers count] == 0) {
        NSXMLNode *connectedAttribute = [self attributeForName:@"connected"];
        [connectedAttribute setStringValue:@"NO"];
        connected = NO;
    }
    OSSpinLockUnlock(&producersLock);

    for (NSXMLElement *element in connections.children) {
        if ([[element attributeForName:@"uid"] isEqual:[destinationPin attributeForName:@"uid"]]) {
            [element detach];
            break;
        }
    }
    if (self.owner) {
        for (NSXMLElement *element in destinationPin.connections.children) {
            if ([[element attributeForName:@"uid"] isEqual:[self attributeForName:@"uid"]]) {
                [element detach];
                break;
            }
        }
    }
    [super disconnectFromPin:destinationPin];
    [destinationPin release];
}

- (void)disconnectAllPins
{
    OSSpinLockLock(&producersLock);
    while ([producers count])
        [self disconnectFromPin:[producers objectAtIndex:0]];
    passiveProducersCount = 0;
    OSSpinLockUnlock(&producersLock);
}

/*
- (int)length
{
    NSLog(@"BLAH");
}*/

@end
