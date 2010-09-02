//
//  VJXObject.m
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntity.h"


@implementation VJXEntity

- (id)init
{
    if (self = [super init]) {
        inputPins = [NSMutableDictionary alloc];
        outputPins = [NSMutableDictionary alloc];
    }
    return self;
}

- (void)dealloc
{
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

- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    [self registerInputPin:pinName withType:pinType andSelector:@selector(defaultInputCallback:)];
}

- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(SEL)selector
{
    [inputPins addObject:[VJXPin pinWithName:pinName andType:pinType forObject:self withSelector:selector]];
}

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    [self registerInputPin:pinName withType:pinType andSelector:@selector(defaultOutputCallback:)];
}

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(SEL)selector
{
    [inputPins addObject:[VJXPin pinWithName:pinName andType:pinType forObject:self withSelector:selector]];
}

- (void)signalOutput:(id)data
{
    
}

@synthesize inputPins, outputPins, name;
@end
