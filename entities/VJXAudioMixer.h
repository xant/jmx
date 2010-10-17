//
//  VJXAudioMixer.h
//  VeeJay
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

typedef enum {
    kVJXAudioMixerCollectMode,
    kVJXAudioMixerAccumulateMode
} VJXAudioMixerMode;

@class VJXPin;
@class VJXAudioBuffer;
@class VJXAudioDevice;

@interface VJXAudioMixer : VJXThreadedEntity {    
@protected
    NSArray *audioInputs;
    VJXPin *audioInputPin;
    VJXPin *audioOutputPin;
@private
    //VJXAudioBuffer *currentSample;
    uint64_t lastSampleTime;
    NSMutableArray *samples;
    VJXAudioMixerMode mode;
    VJXAudioDevice *device;
    BOOL prefill;
}

@property (assign) VJXAudioMixerMode mode;

@end

