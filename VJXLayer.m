//
//  VJLayer.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXLayer

@synthesize alpha, saturation, brightness, contrast, fps,
            rotation, origin, size, scaleRatio, active, currentFrame;

- (id)init
{
    if (self = [super init]) {
        currentFrame = nil;
        fps = [NSNumber numberWithDouble:25]; //defaults to 25 fps
        name = @"Untitled";
        self.saturation = [NSNumber numberWithFloat:1.0];
        self.brightness = [NSNumber numberWithFloat:0.0];
        self.contrast = [NSNumber numberWithFloat:1.0];
        active = NO;
        [self registerInputPin:@"name" withType:kVJXStringPin andSelector:@"setName:"];
        [self registerInputPin:@"alpha" withType:kVJXNumberPin andSelector:@"setAlpha:"];
        [self registerInputPin:@"saturation" withType:kVJXNumberPin andSelector:@"setSaturation:"];
        [self registerInputPin:@"brightness" withType:kVJXNumberPin andSelector:@"setBrightness:"];
        [self registerInputPin:@"contrast" withType:kVJXNumberPin andSelector:@"setContrast:"];
        [self registerInputPin:@"rotation" withType:kVJXNumberPin andSelector:@"setRotation:"];
        [self registerInputPin:@"scaleRatio" withType:kVJXNumberPin andSelector:@"setScaleRatio:"];
        
        [self registerInputPin:@"origin" withType:kVJXPointPin andSelector:@"setOriginPin:"];
        [self registerInputPin:@"size" withType:kVJXSizePin andSelector:@"setSizePin:"];
        
        [self registerInputPin:@"fps" withType:kVJXNumberPin andSelector:@"setFps:"];

        // we output at least 1 image
        [self registerOutputPin:@"outputFrame" withType:kVJXImagePin];
        outputFramePin = [outputPins lastObject]; // save the output pin to signal data when available
        
        // and 'effective' fps , only for debugging purposes
        [self registerOutputPin:@"outputFps" withType:kVJXNumberPin];

    }
    return self;
}

- (void)dealloc
{
    if (currentFrame)
        self.currentFrame = nil; // ensure calling the accessor to release the current frame
    [super dealloc];
}

- (void)setOriginPin:(NSData *)newOrigin
{
    @synchronized(self) {
        // we can trust type-checking done by the VJXPin->signal() method
        memcpy(&origin, [newOrigin bytes], sizeof(origin));
    }
}

- (void)setSizePin:(NSData *)newSize
{
    @synchronized(self) {
        // we can trust type-checking done by the VJXPin->signal() method
        memcpy(&size, [newSize bytes], sizeof(size));
    }
}

- (CIImage *)frameImageForTime:(uint64_t)timeStamp
{
    @synchronized(self) {
        [outputFramePin deliverSignal:currentFrame];
    }
    // TODO - compute the effective fps and send it to an output pin 
    //        for debugging purposes
    return currentFrame;
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
    uint64_t maxDelta = 1e9 / [fps doubleValue];
    
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
        [self frameImageForTime:timeStamp];
        previousTimeStamp = timeStamp;
        [pool drain];
    }
}

@end
