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

- (id)init
{
    if (self = [super init]) {
        inputPins = [[NSMutableArray alloc] init];
        outputPins = [[NSMutableArray alloc] init];
        worker = nil;
        _fps = 25;
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

- (void)signalOutput:(id)data
{
    
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
    uint64_t maxDelta = 1e9 / _fps;
    
    NSThread *currentThread = [NSThread currentThread];
    
    while (![currentThread isCancelled]) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        uint64_t timeStamp = CVGetCurrentHostTime();
        // Calculate delta of current and last time. If the current delta is
        // smaller than the maxDelta for 24fps, we wait the difference between
        // maxDelta and delta. Otherwise we just skip the sleep time and go for
        // the next frame.
        uint64_t delta = previousTimeStamp ? timeStamp - previousTimeStamp : 0;
        uint64_t sleepTime = delta < maxDelta ? maxDelta - delta : 0;
        
        if (sleepTime > 0) {
            // NSLog(@"Will wait %llu nanoseconds", sleepTime);
            struct timespec time = { 0, 0 };
            struct timespec remainder = { 0, sleepTime };
            do {
                //time.tv_sec = remainder.tv_sec;
                time.tv_nsec = remainder.tv_nsec;
                remainder.tv_nsec = 0;
                nanosleep(&time, &remainder);
            } while (remainder.tv_sec || time.tv_nsec);
        } else {
            // mmm ... no sleep time ... perhaps we are out of resources and slowing down mixing
            // TODO - produce a warning in this case
        }
        [self tick:timeStamp];
        previousTimeStamp = timeStamp;
        [pool drain];
    }
}

@synthesize inputPins, outputPins, name;
@end
