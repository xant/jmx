//
//  VJXQtAudioCaptureLayer.h
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"
#import "VJXAudioBuffer.h"

@class VJXQtAudioGrabber;

@interface VJXQtAudioCaptureLayer : VJXEntity < NSCoding >
{
@private
	VJXQtAudioGrabber *grabber;
    VJXAudioBuffer *currentBuffer;
    VJXPin *outputPin;
}

- (void)start;
- (void)stop;
@end
