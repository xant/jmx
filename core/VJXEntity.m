//
//  VJXObject.m
//  VeeJay
//
//  Created by xant on 9/1/10.
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

#import "VJXEntity.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXEntity

@synthesize inputPins, outputPins, name, active;

- (id)init
{
    if (self = [super init]) {
        name = @""; // XXX - default name
        inputPins = [[NSMutableDictionary alloc] init];
        outputPins = [[NSMutableDictionary alloc] init];
        [self registerOutputPin:@"active" withType:kVJXNumberPin];
        selfPin = [self registerOutputPin:@"self" withType:kVJXEntityPin];
        selfPin.continuous = NO;
        [selfPin deliverSignal:self];
        // we want a weak reference becasue we are surely going to live longer than the our pin
        // and if the pin retains us, our [dealloc] won't never be called
        selfPin.retainData = NO;
        
    }
    return self;
}

- (void)dealloc
{
    [self unregisterAllPins];
    [inputPins release];
    [outputPins release];
    [super dealloc];
}

- (void)defaultInputCallback:(id)inputData
{
    
}

- (void)defaultOuputCallback:(id)outputData
{
}

- (VJXPin *)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    return [self registerInputPin:pinName withType:pinType andSelector:@"defaultInputCallback:"];
}

- (VJXPin *)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    [inputPins setObject:[VJXPin pinWithName:pinName andType:pinType forDirection:kVJXInputPin ownedBy:self withSignal:selector]
                  forKey:pinName];
    return [inputPins objectForKey:pinName];
}

- (VJXPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    return [self registerOutputPin:pinName withType:pinType andSelector:@"defaultOutputCallback:"];
}

- (VJXPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    [outputPins setObject:[VJXPin pinWithName:pinName andType:pinType forDirection:kVJXOutputPin ownedBy:self withSignal:selector]
                   forKey:pinName];
    return [outputPins objectForKey:pinName];
}

- (VJXPin *)inputPinWithName:(NSString *)pinName
{
    return [inputPins objectForKey:pinName];
}

- (VJXPin *)outputPinWithName:(NSString *)pinName
{
    return [outputPins objectForKey:pinName];
}

- (void)unregisterInputPin:(NSString *)pinName
{
    VJXPin *pin = [inputPins objectForKey:pinName];
    if (pin) {
        [inputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
}

- (void)unregisterOutputPin:(NSString *)pinName
{
    VJXPin *pin = [outputPins objectForKey:pinName];
    if (pin) {
        [outputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
}

- (void)unregisterAllPins
{
    [self disconnectAllPins];
    [inputPins removeAllObjects];
    [outputPins removeAllObjects];
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    VJXPin *activePin = [self outputPinWithName:@"active"];    
    [activePin deliverSignal:[NSNumber numberWithBool:active] fromSender:self];
}

- (BOOL)attachObject:(id)receiver withSelector:(NSString *)selector toOutputPin:(NSString *)pinName
{
    VJXPin *pin = [self outputPinWithName:pinName];
    if (pin) {
        // create a virtual pin to be attached to the receiver
        // not that the pin will automatically released once disconnected
        VJXPin *vPin = [VJXPin pinWithName:@"vpin" andType:pin.type forDirection:kVJXInputPin ownedBy:receiver withSignal:selector];
        [pin connectToPin:vPin];
        return YES;
    }
    return NO;
}

- (void)setActive:(id)value
{
    active = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
           ? YES
           : NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (void)disconnectAllPins
{
    for (id key in inputPins)
        [[inputPins objectForKey:key] disconnectAllPins];
    for (id key in outputPins)
        [[outputPins objectForKey:key] disconnectAllPins];
}

- (NSString *)description
{
    return [name isEqual:@""]
           ? [self className]
           : [NSString stringWithFormat:@"%@:%@", [self className], name];
}

- (void)activate
{
    active = YES;
}

- (void)deactivate
{
    active = NO;
}

@end
