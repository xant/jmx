//
//  VJXMixer.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXMixer.h"
#import <QuartzCore/QuartzCore.h>


@implementation VJXMixer

@synthesize fps;

- (id) init
{
    if (self = [super init]) {
        [self registerInputPin:@"videoInput" withType:kVJXImagePin andSelector:@"receivedFrame:fromSender:"];
        imageInputPin = [inputPins lastObject];
        [imageInputPin allowMultipleConnections:YES];
        [self registerOutputPin:@"videoOutput" withType:kVJXImagePin];
        imageOutputPin = [inputPins lastObject];
        [imageOutputPin allowMultipleConnections:YES];
        fps = 25; // default to 25 frames per second
    }
    return self;
}

- (void)receivedFrame:(CIImage *)frame fromSender:(id)sender
{
    @synchronized(self) {
        if (!currentFrame) {
            currentFrame = [frame retain];
        }
        else {
            CIFilter *blendScreenFilter = [CIFilter filterWithName:@"CIScreenBlendMode"];
            [blendScreenFilter setDefaults];
            [blendScreenFilter setValue:frame forKey:@"inputImage"];
            [blendScreenFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
            CIImage *resultingImage = [blendScreenFilter valueForKey:@"outputImage"];
            /* TODO - apply filters
            CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
            CGRect imageRect = [resultingImage extent];
            float xScale = 640 / imageRect.size.width;
            float yScale = 480 / imageRect.size.height;
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform scaleXBy:xScale yBy:yScale];
            [filter setDefaults];
            [filter setValue:transform forKey:@"inputTransform"];
            [filter setValue:resultingImage forKey:@"inputImage"];
            
            resultingImage = [filter valueForKey:@"outputImage"];
            */
            [currentFrame release];
            currentFrame = [resultingImage retain];
        }
    }
    
}

- (void)start
{
    if (!worker) {
        worker = [[NSThread alloc] initWithTarget:self selector:@selector(run:) object:nil];
        [worker start];
    
    }
}

- (void)run
{
    uint64_t maxDelta = 1e9 / fps;
    
    NSThread *currentThread = [NSThread currentThread];
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    while (![currentThread isCancelled]) {
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
            time.tv_nsec = sleepTime;
            do {
                time.tv_sec = remainder.tv_sec;
                time.tv_nsec = remainder.tv_nsec;
                nanosleep(&time, &remainder);
            } while (remainder.tv_sec || time.tv_nsec);
        } else {
            // mmm ... no sleep time ... perhaps we are out of resources and slowing down mixing
            // TODO - produce a warning in this case
        }
        @synchronized(self) {
            if (currentFrame) {
                [imageOutputPin deliverSignal:currentFrame fromSender:self];
                [currentFrame release];
                currentFrame = nil;
                // go for next frame
            }
            previousTimeStamp = timeStamp;
        }
        
        [pool drain];
    }
    [pool release];
}

@end
