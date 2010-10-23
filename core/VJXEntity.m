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

@synthesize name, active;

- (void)notifyModifications
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasModified" object:self];
}

- (void)notifyCreation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasCreated" object:self];
}

- (id)init
{
    // TODO - start using debug messages activated by some flag
    //NSLog(@"Initializing %@", [self class]);
    self = [super init];
    if (self) {
        name = @""; // XXX - default name
        inputPins = [[NSMutableDictionary alloc] init];
        outputPins = [[NSMutableDictionary alloc] init];
        [self registerInputPin:@"active" withType:kVJXNumberPin andSelector:@"setActivePin:"];
        [self registerOutputPin:@"active" withType:kVJXNumberPin];
        // delay notification so that the superclass constructor can finish its job
        // since this selector is going to be called in this same thread, we know for sure
        // that it's going to be called after the init-chain has been fully executede
        [self performSelector:@selector(notifyCreation) withObject:nil afterDelay:0.1];
    }
    return self;
}

- (void)dealloc
{
    NSLog(@"VJXEntity dealloc called!!");
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityWasDestroyed" object:self];
    [self unregisterAllPins];
    [inputPins release];
    [outputPins release];
    [super dealloc];
}

- (void)defaultInputCallback:(id)inputData
{
    
}

- (VJXInputPin *)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    return [self registerInputPin:pinName withType:pinType andSelector:@"defaultInputCallback:"];
}

- (VJXInputPin *)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    return [self registerInputPin:pinName withType:pinType andSelector:selector allowedValues:nil initialValue:nil];
}

- (VJXInputPin *)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector userData:(id)userData
{
    return [self registerInputPin:pinName withType:pinType andSelector:selector userData:userData allowedValues:nil initialValue:nil];
}

- (VJXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(VJXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    [inputPins setObject:[VJXPin pinWithName:pinName
                                     andType:pinType
                                forDirection:kVJXInputPin
                                     ownedBy:self
                                  withSignal:selector
                                    userData:userData
                               allowedValues:pinValues
                                initialValue:(id)value]
                  forKey:pinName];
    VJXInputPin *newPin = [inputPins objectForKey:pinName];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:newPin, @"pin", pinName, @"pinName", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityInputPinAdded"
                                                        object:self
                                                      userInfo:userInfo];
    return newPin;
}

- (VJXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(VJXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    return [self registerInputPin:pinName
                         withType:pinType
                      andSelector:selector
                         userData:nil
                    allowedValues:pinValues
                     initialValue:value];
}

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    return [self registerOutputPin:pinName withType:pinType andSelector:nil];
}

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType
                        andSelector:(NSString *)selector
{
    return [self registerOutputPin:pinName
                          withType:pinType
                       andSelector:selector
                     allowedValues:nil
                      initialValue:nil];
}

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector userData:(id)userData
{
    return [self registerOutputPin:pinName withType:pinType andSelector:selector userData:userData allowedValues:nil initialValue:nil];
}

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    [outputPins setObject:[VJXPin pinWithName:pinName
                                      andType:pinType
                                 forDirection:kVJXOutputPin
                                      ownedBy:self
                                   withSignal:selector
                                     userData:userData
                                allowedValues:pinValues
                                 initialValue:(id)value]
                   forKey:pinName];
    VJXOutputPin *newPin = [outputPins objectForKey:pinName];
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:newPin, @"pin", pinName, @"pinName", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityOutputPinAdded" 
                                                        object:self
                                                      userInfo:userInfo];
    return newPin;
}


- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    return [self registerOutputPin:pinName
                          withType:pinType
                       andSelector:selector
                          userData:nil
                     allowedValues:pinValues
                      initialValue:value];
}

- (NSArray *)inputPins
{
    return [[inputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];
}

- (NSArray *)outputPins
{
    return [[outputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];
}

- (VJXInputPin *)inputPinWithName:(NSString *)pinName
{
    return [inputPins objectForKey:pinName];
}

- (VJXOutputPin *)outputPinWithName:(NSString *)pinName
{
    return [outputPins objectForKey:pinName];
}

- (void)unregisterInputPin:(NSString *)pinName
{
    VJXInputPin *pin = [[inputPins objectForKey:pinName] retain];
    if (pin) {
        [inputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pinName, @"pinName", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityInputPinRemoved"
                                                        object:self
                                                      userInfo:userInfo];
    [pin release];
}

- (void)unregisterOutputPin:(NSString *)pinName
{
    VJXOutputPin *pin = [[outputPins objectForKey:pinName] retain];
    if (pin) {
        [outputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pinName, @"pinName", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXEntityOutputPinRemoved"
                                                        object:self 
                                                      userInfo:userInfo];
    // we can now release the pin
    [pin release];
}

- (void)unregisterAllPins
{
    [self disconnectAllPins];
    [inputPins removeAllObjects];
    [outputPins removeAllObjects];
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    VJXOutputPin *activePin = [self outputPinWithName:@"active"];    
    [activePin deliverData:[NSNumber numberWithBool:active] fromSender:self];
}

- (BOOL)attachObject:(id)receiver withSelector:(NSString *)selector toOutputPin:(NSString *)pinName
{
    VJXOutputPin *pin = [self outputPinWithName:pinName];
    if (pin) {
        // create a virtual pin to be attached to the receiver
        // not that the pin will automatically released once disconnected
        VJXInputPin *vPin = [VJXInputPin pinWithName:@"vpin"
                                             andType:pin.type
                                        forDirection:kVJXInputPin
                                             ownedBy:receiver
                                          withSignal:selector];
        [pin connectToPin:vPin];
        return YES;
    }
    return NO;
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

- (void)setActivePin:(id)value
{
    self.active = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
    ? YES
    : NO;
}
         
@end
