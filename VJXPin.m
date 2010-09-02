//
//  VJXConnector.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXPin.h"


@implementation VJXPin

- (id)init
{
    // TODO - generate a warning message
    return [self initWithName:@"Unknown" andType:kVJXVoidPin];
}

+ (id)pinWithName:(NSString *)pinName andType:(VJXPinType)pinType
{
    id obj = [VJXPin alloc];
    return [[obj initWithName:pinName andType:pinType] autorelease];
}

+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType forObject:(id)pinReceiver withSelector:(SEL)pinSignal
{
    id obj = [VJXPin pinWithName:name andType:pinType];
    if (obj)
        [obj attachObject:pinReceiver withSelector:pinSignal];
    return obj;
}


- (id)initWithName:(NSString *)pinName andType:(VJXPinType)pinType
{
    if (self = [super init]) {
        type = pinType;
        name = [pinName retain];
        receiver = nil;
        selector = nil;
    }
    return self;
}

- (void)attachObject:(id)pinReceiver withSelector:(SEL)pinSignal
{
    receiver = pinReceiver;
    selector = pinSignal;
}

- (void)signal:(id)data
{
    id signalData = [NSNull null];
    switch (type) {
        case kVJXStringPin:
            if ([data isKindOfClass:[NSString class]])
                signalData = data;
            break;
        case kVJXNumberPin:
            if ([data isKindOfClass:[NSNumber class]])
                signalData = data;
            break;
        case kVJXImagePin:
            if ([data isKindOfClass:[CIImage class]])
                signalData = data;
            break;
        case kVJXSizePin:
            if ([data isKindOfClass:[NSData class]] && [data length] == sizeof(NSSize))
                signalData = data;
            break;
        case kVJXPointPin:
            if ([data isKindOfClass:[NSData class]] && [data length] == sizeof(NSPoint))
                signalData = data;
            break;
        default:
            NSLog(@"Unkown pin type!\n");
    }
    if (receiver) {
        if ([receiver respondsToSelector:selector])
            [receiver performSelector:selector withObject:data];
    }
}

- (void)dealloc
{
    [name release];
    [super dealloc];
}

@synthesize type, name;
@end
