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
#ifdef POLLING_MODE
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin];
#else
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:fromSender:"];
#endif
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        [audioOutputPin allowMultipleConnections:YES];
        self.frequency = [NSNumber numberWithDouble:44100/512];
#ifdef POLLING_MODE
        ringBuffer = [[NSMutableArray alloc] init];
#else
        producers = [[NSMutableDictionary alloc] init];
#endif
#ifdef AUDIO_MIXER_PREBUFFERING
        needsPrebuffering = YES;
#endif
    }
    return self;
}

- (void)dealloc
{
#ifdef POLLING_MODE
    if (ringBuffer)
        [ringBuffer release];
#else
    if (producers)
        [producers release];
#endif
    [super dealloc];
}

- (void)newSample:(VJXAudioBuffer *)buffer fromSender:(id)sender
{
    if ([sender isKindOfClass:[VJXEntity class]]) {
        @synchronized(self) {
            [producers setObject:buffer forKey:sender];
        }
    }
}


- (void)tick:(uint64_t)timeStamp
{
#if POLLING_MODE
    @synchronized(ringBuffer) {
#ifdef AUDIO_MIXER_PREBUFFERING
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
#else
        if([ringBuffer count]) {
            [audioOutputPin deliverSignal:[ringBuffer objectAtIndex:0] fromSender:self];
            [ringBuffer removeObjectAtIndex:0];
        }
#endif
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
#else
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
#endif
}   

@end
