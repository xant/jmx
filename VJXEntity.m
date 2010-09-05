//
//  VJXObject.m
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntity.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXEntity

@synthesize frequency;

- (id)init
{
    if (self = [super init]) {
        inputPins = [[NSMutableArray alloc] init];
        outputPins = [[NSMutableArray alloc] init];
        worker = nil;
        self.frequency = [NSNumber numberWithDouble:25];
        [self registerInputPin:@"frequency" withType:kVJXNumberPin andSelector:@"setFrequency:"];
        [self registerInputPin:@"active" withType:kVJXNumberPin andSelector:@"setActive:"];
        [self registerOutputPin:@"active" withType:kVJXNumberPin];
        // and 'effective' frequency , only for debugging purposes
        [self registerOutputPin:@"outputFrequency" withType:kVJXNumberPin];
    }
    return self;
}

- (void)dealloc
{
    [self stop];
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
    [self registerInputPin:pinName withType:pinType andSelector:@"defaultInputCallback:"];
}

- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    [inputPins addObject:[VJXPin pinWithName:pinName andType:pinType forObject:self withSelector:selector]];
}

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    [self registerOutputPin:pinName withType:pinType andSelector:@"defaultOutputCallback:"];
}

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    [outputPins addObject:[VJXPin pinWithName:pinName andType:pinType forObject:self withSelector:selector]];
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (VJXPin *)inputPinWithName:(NSString *)pinName
{
    for (id pin in inputPins) {
        if ([pin name] == pinName)
            return pin;
    }
    return nil;
}

- (VJXPin *)outputPinWithName:(NSString *)pinName
{
    for (id pin in outputPins) {
        if ([pin name] == pinName)
            return pin;
    }
    return nil;
}

- (void)unregisterInputPin:(NSString *)pinName
{
    VJXPin *pin = [self inputPinWithName:pinName];
    if (pin) {
        [inputPins removeObject:pin];
        [pin disconnectAllPins];
    }
}

- (void)unregisterOutputPin:(NSString *)pinName
{
    VJXPin *pin = [self inputPinWithName:pinName];
    if (pin) {
        [inputPins removeObject:pin];
        [pin disconnectAllPins];
    }
}

- (void)unregisterAllPins
{
    for (id pin in inputPins) {
        [inputPins removeObject:pin];
        [pin disconnectAllPins];
    }
    for (id pin in outputPins) {
        [outputPins removeObject:pin];
        [pin disconnectAllPins];
    }
}

- (void)tick:(uint64_t)timeStamp
{
    // TODO - base tick implementation 
    //        should call 'producer-callbacks'
    //        for all output pins
    VJXPin *activePin = [self outputPinWithName:@"active"];
    [activePin deliverSignal:[NSNumber numberWithBool:active]];
}

- (void)start
{
    if (!worker) {
        worker = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [worker start];
    }
}

- (void)stop {
    if (worker)
        [worker cancel];
}

- (void)run
{
    uint64_t maxDelta = 1e9 / [frequency doubleValue];
    
    NSThread *currentThread = [NSThread currentThread];
    
    active = YES;
    while (![currentThread isCancelled]) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        uint64_t timeStamp = CVGetCurrentHostTime();
        // Calculate the delta between current and last time. If the current delta is
        // smaller than our frequency, we will wait the difference between
        // maxDelta and delta to honor the configured frequency.
        // Otherwise, since we would be already late, we just skip the sleep time and 
        // go for the next frame.
        uint64_t delta = previousTimeStamp ? timeStamp - previousTimeStamp : 0;
        uint64_t sleepTime = (delta && delta < maxDelta) ? maxDelta - delta : 0;
        
        if (sleepTime) {
#if 0
            // using nanosleep is a good portable way, but since we are running 
            // on OSX only, we should try relying on the NSThread API.
            // We will switch back to nanosleep if we notice that 'sleepForTimeInterval'
            // is not precise enough.
            struct timespec time = { 0, 0 };
            struct timespec remainder = { 0, sleepTime };
            do {
                time.tv_sec = remainder.tv_sec;
                time.tv_nsec = remainder.tv_nsec;
                remainder.tv_nsec = 0;
                nanosleep(&time, &remainder);
            } while (remainder.tv_sec || remainder.tv_nsec);
#else
            // let's try if NSThread facilities are reliable (in terms of time precision)
            [NSThread sleepForTimeInterval:sleepTime/1e9];
#endif
        } else {
            // mmm ... no sleep time ... perhaps we are out of resources and slowing down mixing
            // TODO - produce a warning in this case
        }
        [self tick:timeStamp];
        previousTimeStamp = timeStamp;
        [pool drain];
    }
    active = NO;
}

- (void)setActive:(id)value
{
    active = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
           ? YES
           : NO;
}

@synthesize inputPins, outputPins, name, active;
@end
