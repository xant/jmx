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

@interface VJXAudioMixer : VJXThreadedEntity {    
@protected
    NSArray *audioInputs;
@private
    VJXPin *audioInputPin;
    VJXPin *audioOutputPin;
    //VJXAudioBuffer *currentSample;
    uint64_t lastSampleTime;
    NSMutableDictionary *producers;
    NSMutableArray *preBuffer;
    VJXAudioMixerMode mode;
    BOOL doPrebuffering;
}

@property (assign) VJXAudioMixerMode mode;

@end

