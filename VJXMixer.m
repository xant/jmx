//
//  VJXMixer.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXMixer.h"
#import "VJXLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXMixer

@synthesize outputSize;

- (id) init
{
    if (self = [super init]) {
        //imageInputPin = [self registerInputPin:@"videoInput" withType:kVJXImagePin andSelector:@"receivedFrame:fromSender:"];
        imageInputPin = [self registerInputPin:@"videoInput" withType:kVJXImagePin];
        [imageInputPin allowMultipleConnections:YES];
        imageOutputPin = [self registerOutputPin:@"videoOutput" withType:kVJXImagePin];
        [imageOutputPin allowMultipleConnections:YES];
        outputSize.height = 640; // HC
        outputSize.width = 480; // HC
        imageProducers = [[NSMutableDictionary alloc] init];
        currentFrame = nil;
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
        // if the sender is not a VJXPin,
        // take note of who provided us the frame
        // XXX
        if (![sender isKindOfClass:[VJXPin class]])
            [imageProducers setObject:frame forKey:[sender name]];
    }
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        NSArray *frames = [imageInputPin readProducers];
        for (CIImage *frame in frames) {
        //for (id producer in imageProducers) {
        //    CIImage *frame = [imageProducers objectForKey:producer];
#if 0
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
#endif
            if (!currentFrame)
                currentFrame = [frame retain];
            else {
                CIFilter *blendScreenFilter = [CIFilter filterWithName:@"CIScreenBlendMode"];
                [blendScreenFilter setDefaults];
                [blendScreenFilter setValue:frame forKey:@"inputImage"];
                [blendScreenFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                [currentFrame release];
                currentFrame = [[blendScreenFilter valueForKey:@"outputImage"] retain];
                
            }
        }
        if (currentFrame) {
            [imageOutputPin deliverSignal:currentFrame fromSender:self];
        } else {
            // send a black frame
            CIImage *blackFrame = [CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]];
            [imageOutputPin deliverSignal:blackFrame fromSender:self];
        }
        [imageProducers removeAllObjects];
    }
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
