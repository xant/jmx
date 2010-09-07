//
//  VJXConnector.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXPin.h"

@implementation VJXPin

@synthesize type, name, multiple, direction;

- (id)init
{
    // TODO - generate a warning message
    return [self initWithName:@"Unknown" andType:kVJXVoidPin forDirection:kVJXAnyPin];
}

+ (id)pinWithName:(NSString *)pinName
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection

{
    return [[[self alloc] initWithName:pinName andType:pinType forDirection:pinDirection] autorelease];
}

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
    boundToObject:(id)pinReceiver
     withSelector:(NSString *)pinSignal
{
    VJXPin *obj = [VJXPin pinWithName:name andType:pinType forDirection:pinDirection];
    
    if (obj)
        [obj attachObject:pinReceiver withSelector:pinSignal];
    return obj;
}


- (id)initWithName:(NSString *)pinName andType:(VJXPinType)pinType forDirection:(VJXPinDirection)pinDirection
{
    if (self = [super init]) {
        type = pinType;
        name = [pinName retain];
        receivers = [[NSMutableDictionary alloc] init];
        connections = [[NSMutableArray alloc] init];
        direction = pinDirection;
        multiple = NO;
    }
    return self;
}

- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal
{
    if ([pinReceiver respondsToSelector:NSSelectorFromString(pinSignal)]) {
        if ([[pinSignal componentsSeparatedByString:@":"] count]-1 <= 2) {
            [receivers setObject:pinSignal forKey:pinReceiver];
            return YES;
        } else {
            NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", pinSignal);
        }
    } else {
        NSLog(@"Object %@ doesn't respond to %@\n", pinReceiver, pinSignal);
    }
    return NO;
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
            if ([data isKindOfClass:[VJXSize class]])
                signalData = data;
            break;
        case kVJXPointPin:
            if ([data isKindOfClass:[VJXPoint class]])
                signalData = data;
            break;
        default:
            NSLog(@"Unkown pin type!\n");
    }
    @synchronized(self) {
        // save current data
        if (currentData)
            [currentData release];
        currentData = [signalData retain]; 
        for (id receiver in receivers) {
            NSString *selectorName = [receivers objectForKey:receiver];
            SEL selector = NSSelectorFromString(selectorName);
            int selectorArgsNum = [[selectorName componentsSeparatedByString:@":"] count]-1;
            // checks are now done when registering receivers
            // so we can avoid checking again now if receiver responds to selector and 
            // if the selector expects the correct amount of arguments.
            // this routine is expected to deliver the signals as soon as possible
            // all safety checks must be done before putting new objects in the receivers' table
            switch (selectorArgsNum) {
                case 0:
                    // some listener could be uninterested to the data, 
                    // but just want to get notified when something travels on a pin
                    [receiver performSelector:selector];
                    break;
                case 1:
                    // some other listeners could be interested only in the data,
                    // regardless of the sender
                    [receiver performSelector:selector withObject:data];
                    break;
                case 2:
                    // and finally there can be listeners which require to know also who has sent the data
                    [receiver performSelector:selector withObject:data withObject:sender];
                    break;
                default:
                    NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", selectorName);
            }
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
    [connections release];
    [super dealloc];
}

- (BOOL)connectToPin:(VJXPin *)destinationPin
{
    @synchronized(self) {
        if (!multiple)
            [self disconnectAllPins];
        if (destinationPin.type == self.type) {
            
            if (self.direction == kVJXInputPin) {
                if (destinationPin.direction != kVJXInputPin) {
                    if ([destinationPin attachObject:self withSelector:@"deliverSignal:fromSender:"]) {
                        [connections addObject:destinationPin];
                        return YES;
                    }
                }
            } else if (destinationPin.direction == kVJXInputPin) {
                if (self.direction != kVJXInputPin) 
                    return [destinationPin connectToPin:self];
            } else if (self.direction == kVJXAnyPin) {
                //if (destinationPin.direction == kVJXOutputPin) {
                    if ([self attachObject:self withSelector:@"deliverSignal:fromSender:"]) {
                        [connections addObject:self];
                        return YES;
                    }
                //}
            } else if (destinationPin.direction == kVJXAnyPin) {
                return [destinationPin connectToPin:self];
            }
            
        }
    }
    return NO;
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
    while ([connections count])
        [self disconnectFromPin:[connections objectAtIndex:0]];
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (id)readPinValue
{
    id data;
    @synchronized(self) {
        data = [currentData retain];
    }
    return [data autorelease];
}

@end
