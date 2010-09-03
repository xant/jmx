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
    VJXPin *obj = [[self alloc] init];
    return [[obj initWithName:pinName andType:pinType] autorelease];
}

+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType forObject:(id)pinReceiver withSelector:(NSString *)pinSignal
{
    VJXPin *obj = [VJXPin pinWithName:name andType:pinType];
    
    if (obj)
        [obj attachObject:pinReceiver withSelector:pinSignal];
    return obj;
}


- (id)initWithName:(NSString *)pinName andType:(VJXPinType)pinType
{
    if (self = [super init]) {
        type = pinType;
        name = [pinName retain];
        receivers = [[NSMutableDictionary alloc] init];
        connections = [[NSMutableArray alloc] init];
        multiple = NO;
    }
    return self;
}

- (void)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal
{
    [receivers setObject:pinSignal forKey:pinReceiver];
}

- (void)detachObject:(id)pinReceiver
{
    [receivers removeObjectForKey:pinReceiver];
}

- (void)deliverSignal:(id)data
{
    [self deliverSignal:data fromSender:self];
}

- (void)deliverSignal:(id)data fromSender:(id)sender
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
    for (id receiver in receivers) {
        NSString *selectorName = [receivers objectForKey:receiver];
        int selectorArgsNum = [[selectorName componentsSeparatedByString:@":"] count]-1;
        SEL selector = NSSelectorFromString(selectorName);
        if ([receiver respondsToSelector:selector]) {
        if (selectorArgsNum == 1)
            [receiver performSelector:selector withObject:data];
        else if (selectorArgsNum == 2)
            [receiver performSelector:selector withObject:data withObject:sender];
        else 
            NSLog(@"Unsupported selector : '%@' . It can take either one or two arguments\n");

        } else {
            // TODO - Error Messages
        }
    }
}

- (void)allowMultipleConnections:(BOOL)choice
{
    multiple = choice;
}

- (void)dealloc
{
    [name release];
    [receivers release];
    [super dealloc];
}

- (void)connectToPin:(VJXPin *)destinationPin
{
    @synchronized(self) {
        if (!multiple)
            [self disconnectAllPins];
        if (destinationPin.type == self.type) {
            [destinationPin attachObject:self withSelector:@"deliverSignal:fromSender:"];
            [connections addObject:destinationPin];
        }
    }
}

- (void)disconnectFromPin:(VJXPin *)destinationPin
{
    @synchronized(self) {
        [destinationPin detachObject:self];
        [connections removeObjectIdenticalTo:destinationPin];
    }
}

- (void)disconnectAllPins
{
    id pin;
    while (pin = [connections objectAtIndex:0])
        [self disconnectFromPin:pin];
}


@synthesize type, name, multiple;

@end
