//
//  VJXMixer.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXMixer.h"
#import "VJXLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXMixer

@synthesize outputSize;

- (id) init
{
    if (self = [super init]) {
        [self registerInputPin:@"videoInput" withType:kVJXImagePin andSelector:@"receivedFrame:fromSender:"];
        imageInputPin = [inputPins lastObject];
        [imageInputPin allowMultipleConnections:YES];
        [self registerOutputPin:@"videoOutput" withType:kVJXImagePin];
        imageOutputPin = [outputPins lastObject];
        [imageOutputPin allowMultipleConnections:YES];
        outputSize.height = 480; // HC
        outputSize.width = 640; // HC
        imageProducers = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{    
    [imageProducers release];
    [super dealloc];
}

- (void)receivedFrame:(CIImage *)frame fromSender:(id)sender
{
    @synchronized(self) {
        [imageProducers setObject:frame forKey:sender]; // take note of who provided us a frame in time
    }
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        for (id producer in imageProducers) {
            CIImage *frame = [imageProducers objectForKey:producer];
            if ([producer isKindOfClass:[VJXLayer class]]) {
                VJXLayer *layer = (VJXLayer *)producer;
                if (layer.size.width != outputSize.width || layer.size.height != outputSize.height)
                {
                    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
                    CGRect imageRect = [frame extent];
                    float xScale = outputSize.width / imageRect.size.width;
                    float yScale = outputSize.height / imageRect.size.height;
                    NSAffineTransform *transform = [NSAffineTransform transform];
                    [transform scaleXBy:xScale yBy:yScale];
                    [filter setDefaults];
                    [filter setValue:transform forKey:@"inputTransform"];
                    [filter setValue:frame forKey:@"inputImage"];
                    frame = [filter valueForKey:@"outputImage"];
                }
            }
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
            //[imageProducers removeAllObjects];
            // go for next frame
        }
        [imageOutputPin deliverSignal:currentFrame fromSender:self];
    }
    [super tick:timeStamp];
}

- (NSArray *)imageProducers
{
    NSMutableArray *out = [[[NSMutableArray alloc] init] autorelease];
    @synchronized(self) {
        for (id layer in imageProducers) {
            [out addObject:layer];
        }
    }
    return out;
}

@end
