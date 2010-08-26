//
//  VJController.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXController.h"
#import "VJXMovieLayer.h"
#import "VJXImageLayer.h"

@implementation VJXController

@synthesize layers, outputs, lastImage;

- (id)init
{
    NSLog(@"init");
    if (self = [super init]) {
        layers = [[NSMutableArray alloc] init];
        outputs = [[NSMutableArray alloc] init];
        lastImage = nil;
        worker = nil;
    }

    return self;
}

- (void)awakeFromNib
{
//    NSLog(@"awakeFromNib");
//    VJMovieLayer *layer = [[VJMovieLayer alloc] init];
//    layer.name = @"Test";
//    [layers addObject:layer];
}

- (void)dealloc {
    [layers release];
    [outputs release];
    [worker release];
    [lastImage release];
    [super dealloc];
}

- (void)addOutput:(id)output
{
    [outputs addObject:output];
}

- (CIImage *)frameImageForTime:(uint64_t)timeStamp
{
    CIImage *resultingImage = nil;
    for (VJXMovieLayer *layer in [layers reverseObjectEnumerator]) {
        if (![layer active])
            continue;

        if (!resultingImage) {
            resultingImage = [layer frameImageForTime:timeStamp];
        }
        else {
            CIImage *layerImage = [layer frameImageForTime:timeStamp];
            if (layerImage) {
                CIFilter *blendScreenFilter = [CIFilter filterWithName:@"CIScreenBlendMode"];
                [blendScreenFilter setDefaults];
                [blendScreenFilter setValue:layerImage forKey:@"inputImage"];
                [blendScreenFilter setValue:resultingImage forKey:@"inputBackgroundImage"];
                resultingImage = [blendScreenFilter valueForKey:@"outputImage"];
            }
        }
    }
    return resultingImage;
}

- (IBAction)start:(id)sender
{
    if (!worker) {
        worker = [[NSThread alloc] initWithTarget:self selector:@selector(nextFrame:) object:nil];
        [worker start];
    }
}

- (IBAction)stop:(id)sender
{
    [worker cancel];
    [worker release];
    worker = nil;
}

- (IBAction)addMovieLayer
{
    VJXMovieLayer *layer = [[VJXMovieLayer alloc] init];
    [self willChangeValueForKey:@"layers"];
    [self.layers addObject:layer];
    [self didChangeValueForKey:@"layers"];
    [layer release];
}

- (IBAction)addImageLayer
{
    VJXImageLayer *layer = [[VJXImageLayer alloc] init];
    [self willChangeValueForKey:@"layers"];
    [self.layers addObject:layer];
    [self didChangeValueForKey:@"layers"];
    [layer release];
}

- (void)nextFrame:(id)userInfo
{
    static uint64_t maxDelta = 1e9 / 24;

    NSThread *currentThread = [NSThread currentThread];

    NSAutoreleasePool *pool;

    while (![currentThread isCancelled]) {
        pool = [[NSAutoreleasePool alloc] init];
        uint64_t timeStamp = CVGetCurrentHostTime();

        // Get next frame for given time.
        CIImage *nextFrame = [self frameImageForTime:timeStamp];
        if (nextFrame) {
            [lastImage release];
            lastImage = [nextFrame retain];
        }

        // Should delegate to another thread perhaps.
        [outputs makeObjectsPerformSelector:@selector(tick)];

        // Calculate delta of current and last time. If the current delta is
        // smaller than the maxDelta for 24fps, we wait the difference between
        // maxDelta and delta. Otherwise we just skip the sleep time and go for
        // the next frame.
        uint64_t delta = previousTimeStamp ? timeStamp - previousTimeStamp : 0;
        uint64_t sleepTime = delta < maxDelta ? maxDelta - delta : 0;

        if (sleepTime > 0) {
            // NSLog(@"Will wait %llu nanoseconds", sleepTime);
            struct timespec time;
            time.tv_sec = 0;
            time.tv_nsec = sleepTime;
            nanosleep(&time, NULL);
        }

        previousTimeStamp = timeStamp;

        [pool drain];
        pool = nil;
    }
}

@end
