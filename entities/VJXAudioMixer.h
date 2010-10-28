//
//  VJXAudioMixer.h
//  VeeJay
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

#define kVJXAudioMixerSamplesBufferCount 512

@class VJXPin;
@class VJXAudioBuffer;
@class VJXAudioDevice;

@interface VJXAudioMixer : VJXThreadedEntity {    
@protected
    NSArray *audioInputs;
    VJXInputPin *audioInputPin;
    VJXOutputPin *audioOutputPin;
@private
    //VJXAudioBuffer *currentSample;
    uint64_t lastSampleTime;
    VJXAudioBuffer *samples[kVJXAudioMixerSamplesBufferCount];
    UInt32 rOffset;
    UInt32 wOffset;
    VJXAudioDevice *device;
    VJXAudioFormat *format;
    BOOL prefill; // defaults to YES
    BOOL useAggregateDevice; // defaults to YES
}

@property (readwrite) BOOL useAggregatedDevice;
@end

