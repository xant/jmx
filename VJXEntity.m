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
        inputPins = [[NSMutableDictionary alloc] init];
        outputPins = [[NSMutableDictionary alloc] init];
        worker = nil;
        self.frequency = [NSNumber numberWithDouble:25];
        [self registerInputPin:@"frequency" withType:kVJXNumberPin andSelector:@"setFrequency:"];
        [self registerInputPin:@"active" withType:kVJXNumberPin andSelector:@"setActive:"];
        [self registerOutputPin:@"active" withType:kVJXNumberPin];
        // and 'effective' frequency , only for debugging purposes
        [self registerOutputPin:@"outputFrequency" withType:kVJXNumberPin];
        stampCount = 0;
        previousTimeStamp = 0;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
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
    [inputPins setObject:[VJXPin pinWithName:pinName andType:pinType forDirection:kVJXInputPin boundToObject:self withSelector:selector]
                  forKey:pinName];
    return [inputPins objectForKey:pinName];
}

- (VJXPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType
{
    return [self registerOutputPin:pinName withType:pinType andSelector:@"defaultOutputCallback:"];
}

- (VJXPin *)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector
{
    [outputPins setObject:[VJXPin pinWithName:pinName andType:pinType forDirection:kVJXOutputPin boundToObject:self withSelector:selector]
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
    for (id key in inputPins)
        [[inputPins objectForKey:key] disconnectAllPins];
    [inputPins removeAllObjects];
    for (id key in outputPins)
        [[outputPins objectForKey:key] disconnectAllPins];
    [outputPins removeAllObjects];
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    VJXPin *activePin = [self outputPinWithName:@"active"];
    VJXPin *frequencyPin = [self outputPinWithName:@"outputFrequency"];
    
    [activePin deliverSignal:[NSNumber numberWithBool:active] fromSender:self];
    
    int i = 0;
    if (stampCount > 25) {
        for (i = 0; i < stampCount; i++) {
            stamps[i] = stamps[i+1];
        }
        stampCount = 25;  
    }
    stamps[stampCount++] = timeStamp;
    
    double rate = 1e9/((stamps[stampCount - 1] - stamps[0])/stampCount);
    [frequencyPin deliverSignal:[NSNumber numberWithDouble:rate]
                     fromSender:self];
}

- (BOOL)attachObject:(id)receiver withSelector:(NSString *)selector toOutputPin:(NSString *)pinName
{
    VJXPin *pin = [self outputPinWithName:pinName];
    if (pin) {
        [pin attachObject:receiver withSelector:selector];
        return YES;
    }
    return NO;
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
        [self tick:timeStamp];
        [self outputDefaultSignals:timeStamp]; // ensure sending all default signals
        previousTimeStamp = timeStamp;
        uint64_t now = CVGetCurrentHostTime();
        // Check if tick() has returned earlier and we still have time before next tick. 
        // If the current delta is smaller than our frequency, we will wait the difference
        // between maxDelta and delta to honor the configured frequency.
        // Otherwise, since we would be already late, we just skip the sleep time and 
        // go for the next frame.
        uint64_t delta = now - timeStamp;
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

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

@synthesize inputPins, outputPins, name, active;
@end
