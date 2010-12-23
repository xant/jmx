//
//  JMXAudioMixer.h
//  JMX
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"

#define kJMXAudioMixerSamplesBufferCount 512

@class JMXPin;
@class JMXAudioBuffer;
@class JMXAudioDevice;

@interface JMXAudioMixer : JMXEntity {    
@protected
    NSArray *audioInputs;
    JMXInputPin *audioInputPin;
    JMXOutputPin *audioOutputPin;
@private
    //JMXAudioBuffer *currentSample;
    uint64_t lastSampleTime;
    JMXAudioBuffer *samples[kJMXAudioMixerSamplesBufferCount];
    UInt32 rOffset;
    UInt32 wOffset;
    JMXAudioDevice *device;
    JMXAudioFormat *format;
    BOOL prefill; // defaults to YES
    BOOL useAggregateDevice; // defaults to YES
}

@property (readwrite) BOOL useAggregateDevice;
@end

