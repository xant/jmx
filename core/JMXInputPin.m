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
        [self addAttribute:[NSXMLNode attributeWithName:@"direction" stringValue:@"input"]];
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
        for (JMXOutputPin *producer in producers) {
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
            JMXOutputPin *obj = [[producers objectAtIndex:src] retain];
            [producers removeObjectAtIndex:src];
            [producers insertObject:obj atIndex:dst];
            [obj release];
            return YES;
        }
    }
    return NO;
}

- (BOOL)connectToPin:(JMXOutputPin *)destinationPin
{
    if (self.type == destinationPin.type) {
        @synchronized(producers) {
            if ([producers count] && !multiple) {
                    [[producers objectAtIndex:0] detachObject:self];
                    [super disconnectFromPin:[producers objectAtIndex:0]];
                    [producers removeObjectAtIndex:0];
            }
            if ([destinationPin attachObject:self withSelector:@"deliverData:fromSender:"]) {
                [producers addObject:destinationPin];
                connected = YES;
                NSXMLNode *connectedAttribute = [self attributeForName:@"connected"];
                [connectedAttribute setStringValue:@"YES"];
                return [super connectToPin:destinationPin];
            }
        }
    }
    return NO;
}

- (void)disconnectFromPin:(JMXOutputPin *)destinationPin
{
    [destinationPin retain];
    @synchronized(producers) {
        [destinationPin detachObject:self];
        [producers removeObjectIdenticalTo:destinationPin];
        if ([producers count] == 0) {
            NSXMLNode *connectedAttribute = [self attributeForName:@"connected"];
            [connectedAttribute setStringValue:@"NO"];
            connected = NO;
        }
    }
    if (destinationPin.owner) {
        NSArray *children = [connections elementsForName:[destinationPin.owner description]];
        for (NSXMLElement *element in children) {
            if ([element.stringValue isEqualTo:destinationPin.label])
                [element detach];
        }
    }
    if (self.owner) {
        NSArray *children = [destinationPin.connections elementsForName:[self.owner description]];
        for (NSXMLElement *element in children) {
            if ([element.stringValue isEqualTo:self.label])
                [element detach];
        }
    }
    [super disconnectFromPin:destinationPin];
    [destinationPin release];
}

- (void)disconnectAllPins
{
    @synchronized(producers) {
        while ([producers count])
            [self disconnectFromPin:[producers objectAtIndex:0]];
    }
}

/*
- (int)length
{
    NSLog(@"BLAH");
}*/

@end
