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
#import "VJXAudioDevice.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXAudioMixer

@synthesize useAggregatedDevice;

- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin];
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        [audioOutputPin allowMultipleConnections:YES];
        self.frequency = [NSNumber numberWithDouble:(44100/512)+1];
        samples = [[NSMutableArray alloc] init];
        useAggregateDevice = NO;
        prefill = YES;
        format = nil;
    }
    return self;
}

- (void)dealloc
{
    if (samples)
        [samples release];
    if (device)
        [device release];
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    
    if ([samples count] && !prefill) {
        VJXAudioBuffer *outSample = [samples objectAtIndex:0];
        [audioOutputPin deliverData:outSample fromSender:self];
        @synchronized(samples) {
            [samples removeObjectAtIndex:0];
        }
    }
    NSArray *newSamples = [audioInputPin readProducers];
    VJXAudioBuffer *currentSample = nil;
    for (VJXAudioBuffer *sample in newSamples) {
        if (!currentSample) {
            AudioStreamBasicDescription sampleFormat = sample.format.audioStreamBasicDescription;
            currentSample = [VJXAudioBuffer audioBufferWithCoreAudioBufferList:sample.bufferList andFormat:&sampleFormat];
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
    if (currentSample) {
        @synchronized(samples) {
            [samples addObject:currentSample];
        }
    }
    if ([samples count] > 10)
        prefill = NO;
    else if ([samples count] == 0)
        prefill = YES;
    [super outputDefaultSignals:timeStamp];
}

- (void)provideSamplesToDevice:(VJXAudioDevice *)device
                     timeStamp:(AudioTimeStamp *)timeStamp
                     inputData:(AudioBufferList *)inInputData
                     inputTime:(AudioTimeStamp *)inInputTime
                    outputData:(AudioBufferList *)outOutputData
                    outputTime:(AudioTimeStamp *)inOutputTime
                    clientData:(VJXAudioMixer *)clientData

{
    if ([samples count]) {
        VJXAudioBuffer *sample = nil;
        @synchronized(samples) {
            sample = [[samples objectAtIndex:0] retain];
            if (sample) {
                int i;
                for (i = 0; i < inInputData->mNumberBuffers; i++) {
                    SInt32 bytesToCopy = MIN(inInputData->mBuffers[i].mDataByteSize, sample.bufferList->mBuffers[i].mDataByteSize);
                    if (inInputData->mBuffers[i].mData && sample.bufferList->mNumberBuffers > i) {
                        memcpy(inInputData->mBuffers[i].mData,
                               sample.bufferList->mBuffers[i].mData,
                               bytesToCopy);
                        inInputData->mBuffers[i].mDataByteSize = bytesToCopy;
                        inInputData->mBuffers[i].mNumberChannels = sample.bufferList->mBuffers[i].mNumberChannels;
                    }
                }
            }
        }
        
    }
    [clientData tick:CVGetCurrentHostTime()];
}


- (void)start
{
    if (self.active)
        return;
    
    if (useAggregateDevice) {
        device = [[VJXAudioDevice aggregateDevice:@"VJXMixerNew"] retain];
        [device setIOTarget:self 
               withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
             withClientData:self];
        format = [[device streamDescriptionForChannel:0 forDirection:kVJXAudioInput] retain];
        [self activate];
        [device deviceStart];
    } else { // start the thread only if don't want to use the aggregate device
        [super start];
    }
}

- (void)stop
{
    if (!self.active)
        return;
    if (useAggregateDevice) {
        [self deactivate];
        if (device) {
            [device deviceStop];
            [device release];
            device = nil;
            [format release];
            format = nil;
        }
    } else { // start the thread only if don't want to use the aggregate device
        [super stop];
    }
}

- (void)setUseAggregateDevice:(BOOL)value
{
    // refulse to change the flag if we are running
    // TODO - we should just stop/restart and allow 
    //        changing the mode while running
    if (!self.active)
        useAggregateDevice = value;
}

@end
