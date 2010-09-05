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

@synthesize alpha, saturation, brightness, contrast, rotation,
            origin, size, scaleRatio, fps, currentFrame;

- (id)init
{
    if (self = [super init]) {
        currentFrame = nil;
        name = @"Untitled";
        self.saturation = [NSNumber numberWithFloat:1.0];
        self.brightness = [NSNumber numberWithFloat:0.0];
        self.contrast = [NSNumber numberWithFloat:1.0];
        [self registerInputPin:@"name" withType:kVJXStringPin andSelector:@"setName:"];
        [self registerInputPin:@"alpha" withType:kVJXNumberPin andSelector:@"setAlpha:"];
        [self registerInputPin:@"saturation" withType:kVJXNumberPin andSelector:@"setSaturation:"];
        [self registerInputPin:@"brightness" withType:kVJXNumberPin andSelector:@"setBrightness:"];
        [self registerInputPin:@"contrast" withType:kVJXNumberPin andSelector:@"setContrast:"];
        [self registerInputPin:@"rotation" withType:kVJXNumberPin andSelector:@"setRotation:"];
        [self registerInputPin:@"scaleRatio" withType:kVJXNumberPin andSelector:@"setScaleRatio:"];
        
        [self registerInputPin:@"origin" withType:kVJXPointPin andSelector:@"setOriginPin:"];
        [self registerInputPin:@"size" withType:kVJXSizePin andSelector:@"setSizePin:"];

        // we output at least 1 image
        [self registerOutputPin:@"outputFrame" withType:kVJXImagePin];
        outputFramePin = [outputPins lastObject]; // save the output pin to signal data when available
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

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        // TODO - apply filters
         CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
         [colorFilter setDefaults];
         [colorFilter setValue:self.saturation forKey:@"inputSaturation"];
         [colorFilter setValue:self.brightness forKey:@"inputBrightness"];
         [colorFilter setValue:self.contrast forKey:@"inputContrast"];
         [colorFilter setValue:self.currentFrame forKey:@"inputImage"];
         self.currentFrame = [colorFilter valueForKey:@"outputImage"];
        // TODO - compute the effective fps and send it to an output pin 
        //        for debugging purposes
        [outputFramePin deliverSignal:currentFrame];
    }
    [super tick:timeStamp];
}

@end
