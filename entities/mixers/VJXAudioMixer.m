//
//  VJXAudioMixer.m
//  VeeJay
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioMixer.h"
#include <Accelerate/Accelerate.h>
#import "VJXAudioFormat.h"

#define AUDIO_MIXER_PREBUFFERING 0
#define POLLING_MODE 1

@implementation VJXAudioMixer

- (id)init
{
    if (self = [super init]) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:fromSender:"];
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        [audioOutputPin allowMultipleConnections:YES];
        self.frequency = [NSNumber numberWithDouble:44100/512];
        ringBuffer = [[NSMutableArray alloc] init];
        producers = [[NSMutableDictionary alloc] init];
        mode = kVJXAudioMixerPollingMode;
        buffered = NO;
        needsPrebuffering = YES; // this must be initially set to true
                                 // regardless of the 'buffered' flag
    }
    return self;
}

- (void)dealloc
{
    if (ringBuffer)
        [ringBuffer release];
    if (producers)
        [producers release];
    [super dealloc];
}

- (void)newSample:(VJXAudioBuffer *)buffer fromSender:(id)sender
{
    if (mode == kVJXAudioMixerCollectMode) {
        if ([sender isKindOfClass:[VJXEntity class]]) {
            @synchronized(self) {
                [producers setObject:buffer forKey:sender];
            }
        }
    }
}


- (void)tick:(uint64_t)timeStamp
{
    if (mode == kVJXAudioMixerPollingMode) {
        @synchronized(ringBuffer) {
            if (buffered) {
                if (needsPrebuffering) {
                    if ([ringBuffer count] >= 50) {
                        needsPrebuffering = NO;
                    }
                } else {
                    if ([ringBuffer count] == 0) {
                        needsPrebuffering = YES;
                    } else {
                        [audioOutputPin deliverSignal:[ringBuffer objectAtIndex:0] fromSender:self];
                        //NSLog(@"%d\n",[ringBuffer count]);
                        [ringBuffer removeObjectAtIndex:0];
                    }
                }
            }
            else {
                if([ringBuffer count]) {
                    [audioOutputPin deliverSignal:[ringBuffer objectAtIndex:0] fromSender:self];
                    [ringBuffer removeObjectAtIndex:0];
                }
            }
        }
        NSArray *samples = [audioInputPin readProducers];
        @synchronized(self) {
            if (currentSample) {
                [currentSample release];
                currentSample = nil;
            }
            for (VJXAudioBuffer *sample in samples) {
                if (!currentSample) {
                    AudioStreamBasicDescription format = sample.format.audioStreamBasicDescription;
                    currentSample = [[VJXAudioBuffer audioBufferWithCoreAudioBufferList:sample.bufferList andFormat:&format] retain];
                } else {
                    unsigned x, numSamples;
                    Float32 * srcBuffer, *dstBuffer;

                    for ( x = 0; x < currentSample.bufferList->mNumberBuffers; x++ )
                    {
                        numSamples = ( MIN(currentSample.bufferList->mBuffers[x].mDataByteSize, sample.bufferList->mBuffers[x].mDataByteSize)) / sizeof(Float32);
                        dstBuffer = currentSample.bufferList->mBuffers[x].mData;
                        srcBuffer = sample.bufferList->mBuffers[x].mData;
                        vDSP_vadd ( srcBuffer, 1, dstBuffer, 1, dstBuffer, 1, numSamples );
                    }
                }
            }
            if (currentSample)
                [ringBuffer addObject:currentSample];
        }
    } else if (mode == kVJXAudioMixerCollectMode) {
        @synchronized(self) {
            if (currentSample)
                [currentSample release];
            currentSample = nil;
            for (VJXEntity *producer in producers) {
                VJXAudioBuffer *sample = [producers objectForKey:producer];
                if (!currentSample) {
                    AudioStreamBasicDescription format = sample.format.audioStreamBasicDescription;
                    currentSample = [[VJXAudioBuffer audioBufferWithCoreAudioBufferList:sample.bufferList andFormat:&format] retain];
                } else {
                    unsigned x, numSamples;
                    Float32 * srcBuffer, *dstBuffer;
                    
                    for ( x = 0; x < currentSample.bufferList->mNumberBuffers; x++ )
                    {
                        numSamples = ( MIN(currentSample.bufferList->mBuffers[x].mDataByteSize, sample.bufferList->mBuffers[x].mDataByteSize)) / sizeof(Float32);
                        dstBuffer = currentSample.bufferList->mBuffers[x].mData;
                        srcBuffer = sample.bufferList->mBuffers[x].mData;
                        vDSP_vadd ( srcBuffer, 1, dstBuffer, 1, dstBuffer, 1, numSamples );
                    }
                }
            }
            [audioOutputPin deliverSignal:currentSample fromSender:self];
        }
        [producers removeAllObjects];
    }
}

@end
