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
        imageOutputPin = [outputPins lastObject];
        [imageOutputPin allowMultipleConnections:YES];
        fps = 25; // default to 25 frames per second
        _fps = 25; // XXX
        inputStats = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{    
    [inputStats release];
    [super dealloc];
}

- (void)receivedFrame:(CIImage *)frame fromSender:(id)sender
{
    @synchronized(self) {
        if ([inputStats objectForKey:sender]) {
            // we already got a frame from this sender during
            // actual runcycle ... so let's skip this frame
            // TODO - take note of inputs' framerates to produce stats
            return;
        }
        [inputStats setObject:@"1" forKey:sender]; // take note of who provided us a frame in time
        if (!currentFrame)
            currentFrame = [frame retain];
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

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (currentFrame) {
            [imageOutputPin deliverSignal:currentFrame fromSender:self];
            [currentFrame release];
            currentFrame = nil;
            // TODO - copute stats by looking at who provided frames in the last runcycle
            //        and at which rates each is providing frames
            [inputStats removeAllObjects];
            // go for next frame
        }
        previousTimeStamp = timeStamp;
    }
}

@end
