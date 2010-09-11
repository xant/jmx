//
//  VJLayer.m
//  VeeJay
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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

#import "VJXLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXLayer

@synthesize alpha, saturation, brightness, contrast, rotation,
            origin, size, scaleRatio, fps;

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
        [self registerInputPin:@"origin" withType:kVJXPointPin andSelector:@"setOrigin:"];
        [self registerInputPin:@"size" withType:kVJXSizePin andSelector:@"setSize:"];

        // we output at least 1 image
        outputFramePin = [self registerOutputPin:@"outputFrame" withType:kVJXImagePin];
        outputFrameSizePin = [self registerOutputPin:@"outputFrameSize" withType:kVJXSizePin];
        [outputFrameSizePin allowMultipleConnections:YES];
        // XXX - DEFAULTS
        NSSize defaultLayerSize = { 640, 480 };
        self.size = [VJXSize sizeWithNSSize:defaultLayerSize];
    }
    return self;
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    self.size = nil;
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (currentFrame) {
            // Apply image parameters
            CIFilter *colorFilter = [CIFilter filterWithName:@"CIColorControls"];
            [colorFilter setDefaults];
            [colorFilter setValue:saturation forKey:@"inputSaturation"];
            [colorFilter setValue:brightness forKey:@"inputBrightness"];
            [colorFilter setValue:contrast forKey:@"inputContrast"];
            [colorFilter setValue:currentFrame forKey:@"inputImage"];
            // scale the image to fit the configured layer size
            CIImage *frame = [colorFilter valueForKey:@"outputImage"];
            
#if 0       // frame should be produced with the correct size already by the layer implementation
            CGRect imageRect = [frame extent];
            // and scale the frame if necessary
            if (size.width != imageRect.size.width || size.height != imageRect.size.height) {
                CIFilter *scaleFilter = [CIFilter filterWithName:@"CIAffineTransform"];
                float xScale = size.width / imageRect.size.width;
                float yScale = size.height / imageRect.size.height;
                // TODO - take scaleRatio into account for further scaling requested by the user
                NSAffineTransform *transform = [NSAffineTransform transform];
                [transform scaleXBy:xScale yBy:yScale];
                [scaleFilter setDefaults];
                [scaleFilter setValue:transform forKey:@"inputTransform"];
                [scaleFilter setValue:frame forKey:@"inputImage"];
                frame = [scaleFilter valueForKey:@"outputImage"];
            } 
#endif
            if (frame) {
                [currentFrame release];
                currentFrame = [frame retain];
            }
            // TODO - compute the effective fps and send it to an output pin 
            //        for debugging purposes
            [outputFramePin deliverSignal:currentFrame fromSender:self];
            [outputFrameSizePin deliverSignal:size];
        }
    }
}

- (CIImage *)currentFrame
{   
    @synchronized(self) {
        if (currentFrame) {
            CIImage *frame = [currentFrame retain];
            return [frame autorelease];
        }
    }
    return nil;
}

@end
