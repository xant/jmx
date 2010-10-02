//
//  VJXQtAudioCaptureLayer.h
//  VeeJay
//
//  Created by xant on 9/15/10.
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
#import <AudioToolbox/AudioToolbox.h>
#import "VJXEntity.h"
#import "VJXAudioBuffer.h"
#import "VJXThread.h"

@class VJXQtAudioGrabber;

@interface VJXQtAudioCaptureLayer : VJXEntity < NSCoding, VJXThread >
{
@private
	VJXQtAudioGrabber *grabber;
    VJXAudioBuffer *currentBuffer;
    VJXPin *outputPin;
    AudioConverterRef converter;
    AudioStreamBasicDescription outputFormat;
}
- (void)start;
- (void)stop;
@end
