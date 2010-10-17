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

@synthesize mode;

- (id)init
{
    if (self = [super init]) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin];
        [audioInputPin allowMultipleConnections:YES];
        audioOutputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        [audioOutputPin allowMultipleConnections:YES];
        self.frequency = [NSNumber numberWithDouble:44100/512]; // XXX - I'm unsure the mixer really needs to run at double speed
        samples = [[NSMutableArray alloc] init];
        device = [[VJXAudioDevice aggregateDevice:[[VJXAudioDevice defaultOutputDevice] deviceUID] withName:@"VJXMixer"] retain];
        NSLog(@"%@", [device deviceName]);
        
        [device setIOTarget:self 
               withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
             withClientData:self];
        //if (active)
            [device deviceStart];
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
    // TODO - implement
}

- (void)stop
{
    // TODO - implement
}

@end
