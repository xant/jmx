//
//  VJXAudioOutput.h
//  VeeJay
//
//  Created by xant on 9/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioConverter.h>
#import "VJXEntity.h"

@class VJXAudioBuffer;

@interface VJXAudioOutput : VJXEntity {
    NSMutableArray *ringBuffer;
    AudioConverterRef converter;
}

- (VJXAudioBuffer *)currentSample;

@end
