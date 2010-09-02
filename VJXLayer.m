//
//  VJLayer.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXLayer.h"

@implementation VJXLayer

@synthesize alpha, saturation, brightness, contrast, fps,
            rotation, origin, size, scaleRatio, active, currentFrame;

- (id)init
{
    if (self = [super init]) {
        currentFrame = nil;

        name = @"Untitled";
        self.saturation = [NSNumber numberWithFloat:1.0];
        self.brightness = [NSNumber numberWithFloat:0.0];
        self.contrast = [NSNumber numberWithFloat:1.0];
        active = NO;
        [self registerInputPin:@"name" withType:kVJXStringPin andSelector:@selector(setName:)];
        [self registerInputPin:@"alpha" withType:kVJXNumberPin andSelector:@selector(setAlpha:)];
        [self registerInputPin:@"saturation" withType:kVJXNumberPin andSelector:@selector(setSaturation:)];
        [self registerInputPin:@"brightness" withType:kVJXNumberPin andSelector:@selector(setBrightness:)];
        [self registerInputPin:@"contrast" withType:kVJXNumberPin andSelector:@selector(setContrast:)];
        [self registerInputPin:@"rotation" withType:kVJXNumberPin andSelector:@selector(setRotation:)];
        [self registerInputPin:@"scaleRatio" withType:kVJXNumberPin andSelector:@selector(setScaleRatio:)];
        
        [self registerInputPin:@"origin" withType:kVJXPointPin andSelector:@selector(setOriginPin:)];
        [self registerInputPin:@"size" withType:kVJXSizePin andSelector:@selector(setSizePin:)];
        
        [self registerInputPin:@"fps" withType:kVJXNumberPin andSelector:@selector(setFps:)];

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
        [outputFramePin signal:currentFrame];
    }
    // TODO - compute the effective fps and send it to an output pin 
    //        for debugging purposes
    return currentFrame;
}

@end
