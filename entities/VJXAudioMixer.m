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
    if (self = [super init]) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin];
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        [audioOutputPin allowMultipleConnections:YES];
        self.frequency = [NSNumber numberWithDouble:44100/512];
        samples = [[NSMutableArray alloc] init];
        useAggregateDevice = YES;
        prefill = YES;
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
        [audioOutputPin deliverSignal:outSample fromSender:self];
        [samples removeObjectAtIndex:0];
        [outSample release];
    }
    NSArray *newSamples = [audioInputPin readProducers];
    //@synchronized(self) {
    VJXAudioBuffer *currentSample = nil;
    /*if (currentSample) {
     [currentSample release];
     currentSample = nil;
     }*/
    for (VJXAudioBuffer *sample in newSamples) {
        if (!currentSample) {
            AudioStreamBasicDescription format = sample.format.audioStreamBasicDescription;
            currentSample = [VJXAudioBuffer audioBufferWithCoreAudioBufferList:sample.bufferList andFormat:&format];
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
        [samples addObject:[currentSample retain]];
    if ([samples count] > 10)
        prefill = NO;
    else if ([samples count] == 0)
        prefill = YES;
    //}
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
    [clientData tick:CVGetCurrentHostTime()];
}


- (void)start
{
    if (self.active)
        return;
    
    if (useAggregateDevice) {
        device = [[VJXAudioDevice aggregateDevice:[[VJXAudioDevice defaultInputDevice] deviceUID] withName:@"VJXMixer"] retain];
        [device setIOTarget:self 
               withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
             withClientData:self];
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
