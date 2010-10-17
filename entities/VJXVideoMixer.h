//
//  VJXVideoMixer.h
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

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

#define VJX_MIXER_DEFAULT_VIDEOSIZE_WIDTH 640
#define VJX_MIXER_DEFAULT_VIDEOSIZE_HEIGHT 480
#define VJX_MIXER_DEFAULT_BLEND_FILTER @"CIScreenBlendMode"

@interface VJXVideoMixer : VJXEntity < VJXRunLoop > {
@public
    VJXSize *outputSize;

@protected
    NSArray *videoInputs;
@private
    VJXPin *imageInputPin;
    VJXPin *imageOutputPin;
    VJXPin *imageSizeOutputPin;
    CIImage *currentFrame;
    CIFilter *blendFilter;
    uint64_t lastFrameTime;
}

@property (retain) VJXSize *outputSize;

@end
