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
        outputSize.height = 480; // HC
        outputSize.width = 640; // HC
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
        [inputStats setObject:frame forKey:sender]; // take note of who provided us a frame in time
    }
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        for (id key in inputStats) {
            CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
            CGRect imageRect = [[inputStats objectForKey:key] extent];
            float xScale = outputSize.width / imageRect.size.width;
            float yScale = outputSize.height / imageRect.size.height;
            NSAffineTransform *transform = [NSAffineTransform transform];
            [transform scaleXBy:xScale yBy:yScale];
            [filter setDefaults];
            [filter setValue:transform forKey:@"inputTransform"];
            [filter setValue:[inputStats objectForKey:key] forKey:@"inputImage"];
            CIImage *frame = [filter valueForKey:@"outputImage"];
            if (!currentFrame)
                currentFrame = frame;
            else {
                CIFilter *blendScreenFilter = [CIFilter filterWithName:@"CIScreenBlendMode"];
                [blendScreenFilter setDefaults];
                [blendScreenFilter setValue:frame forKey:@"inputImage"];
                [blendScreenFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                CIImage *resultingImage = [blendScreenFilter valueForKey:@"outputImage"];
                /* TODO - apply filters
                 resultingImage = [filter valueForKey:@"outputImage"];
                 */
                currentFrame = resultingImage;
                
            }
            // TODO - copute stats by looking at who provided frames in the last runcycle
            //        and at which rates each is providing frames
            //[inputStats removeAllObjects];
            // go for next frame
        }
        previousTimeStamp = timeStamp;
        [imageOutputPin deliverSignal:currentFrame fromSender:self];
    }
}

@end
