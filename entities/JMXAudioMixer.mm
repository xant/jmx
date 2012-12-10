//
//  JMXAudioMixer.m
//  JMX
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXAudioMixer.h"
#include <Accelerate/Accelerate.h>
#import "JMXAudioFormat.h"
#import "JMXAudioDevice.h"
#import <QuartzCore/QuartzCore.h>
#import "JMXThreadedEntity.h"

@implementation JMXAudioMixer

@synthesize outputAudio;

- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kJMXAudioPin];
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kJMXAudioPin andSelector:@"outputAudio"];
        audioOutputPin.mode = kJMXPinModePassive;
        [audioOutputPin allowMultipleConnections:YES];
        //self.frequency = [NSNumber numberWithDouble:(44100/512)*2];
        return self;
    }
    return nil;
}

- (void)dealloc
{
    [super dealloc];
}

- (JMXAudioBuffer *)outputAudio
{
    NSArray *newSamples = [audioInputPin readProducers];
    JMXAudioBuffer *currentSample = nil;
    for (JMXAudioBuffer *sample in newSamples) {
        if (!currentSample) { // make a copy
            AudioStreamBasicDescription sampleFormat = sample.format.audioStreamBasicDescription;
            currentSample = [JMXAudioBuffer audioBufferWithCoreAudioBufferList:sample.bufferList andFormat:&sampleFormat];
        } else { // blend samples
            unsigned x, numSamples;
            Float32 * srcBuffer, *dstBuffer;
            
            for ( x = 0; x < currentSample.bufferList->mNumberBuffers; x++ )
            {
                numSamples = ( MIN(currentSample.bufferList->mBuffers[x].mDataByteSize, sample.bufferList->mBuffers[x].mDataByteSize)) / sizeof(Float32);
                dstBuffer = (Float32 *)currentSample.bufferList->mBuffers[x].mData;
                srcBuffer = (Float32 *)sample.bufferList->mBuffers[x].mData;
                vDSP_vadd ( srcBuffer, 1, dstBuffer, 1, dstBuffer, 1, numSamples );
            }
        }
    }
    return currentSample;
}

@end
