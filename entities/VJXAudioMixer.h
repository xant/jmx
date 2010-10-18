//
//  VJXAudioMixer.h
//  VeeJay
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

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
    NSMutableArray *samples;
    VJXAudioDevice *device;
    BOOL prefill; // defaults to YES
    BOOL useAggregateDevice; // defaults to YES
}

@property (readwrite) BOOL useAggregatedDevice;
@end

