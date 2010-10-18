//
//  VJXVideoMixer.m
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

#import "VJXVideoMixer.h"
#import "VJXLayer.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXVideoMixer

@synthesize outputSize;

- (id) init
{
    if (self = [super init]) {
        VJXPin *aPin = [self registerInputPin:@"blendFilter" withType:kVJXStringPin andSelector:@"setBlendFilter:"];
		[aPin addAllowedValue:@"CIScreenBlendMode"];
		[aPin addAllowedValue:@"CISaturationBlendMode"];
        [aPin addAllowedValue:@"CIHueBlendMode"];
		[aPin deliverSignal:VJX_MIXER_DEFAULT_BLEND_FILTER];
        imageInputPin = [self registerInputPin:@"video" withType:kVJXImagePin];
        [imageInputPin allowMultipleConnections:YES];
        [self registerInputPin:@"videoSize" withType:kVJXSizePin andSelector:@"setOutputSize:"];
        imageSizeOutputPin = [self registerOutputPin:@"videoSize" withType:kVJXSizePin];
        [imageSizeOutputPin allowMultipleConnections:YES];
        imageOutputPin = [self registerOutputPin:@"video" withType:kVJXImagePin];
        [imageOutputPin allowMultipleConnections:YES];
        NSSize defaultSize = { VJX_MIXER_DEFAULT_VIDEOSIZE_WIDTH, VJX_MIXER_DEFAULT_VIDEOSIZE_HEIGHT };
        self.outputSize = [VJXSize sizeWithNSSize:defaultSize];
        currentFrame = nil;
		// blendFilter = [[CIFilter filterWithName:VJX_MIXER_DEFAULT_BLEND_FILTER] retain];
    }
    return self;
}

- (void)dealloc
{    
    [super dealloc];
}

- (void)setBlendFilter:(NSString *)blendFilterName
{
    if (!blendFilter || (blendFilter && ![blendFilterName isEqual:[[blendFilter attributes] 
                                                                   objectForKey:@"CIAttributeFilterName"]]))
    {
        @synchronized(self) {
            CIFilter *newBlendFilter = [CIFilter filterWithName:blendFilterName];
            if (newBlendFilter) {
                if (blendFilter)
                    [blendFilter release];
                blendFilter = [newBlendFilter retain];
            }
        }
    }
}

- (void)tick:(uint64_t)timeStamp
{
    NSArray *frames = [imageInputPin readProducers];
    @synchronized(self) {
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        for (CIImage *frame in frames) {
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
            if (!currentFrame) {
                currentFrame = frame;
            } else {
                /*
                if (!blendFilter)
                    blendFilter = [[CIFilter filterWithName:VJX_MIXER_DEFAULT_BLEND_FILTER] retain];
                 */ 
                [blendFilter setDefaults];
                [blendFilter setValue:frame forKey:@"inputImage"];
                [blendFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                currentFrame = [blendFilter valueForKey:@"outputImage"];
            }
        }
        if (currentFrame)
            [currentFrame retain];
        else // send a black frame
            currentFrame = [[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]] retain];
        [imageOutputPin deliverSignal:currentFrame fromSender:self];
        [imageSizeOutputPin deliverSignal:outputSize];
    }
}   

@end
