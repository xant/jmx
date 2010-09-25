//
//  VJXCoreAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXCoreAudioOutput.h"


@implementation VJXCoreAudioOutput

- (id)init
{
    if (self == [super init]) {
        outputDevice = [[VJXAudioDevice defaultOutputDevice] retain];
        [outputDevice setIOTarget:self withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:) withClientData:self];
        [outputDevice deviceStart];
    }
    return self;
}

- (void)provideSamplesToDevice:(VJXAudioDevice *)device
                     timeStamp:(AudioTimeStamp *)timeStamp
                     inputData:(AudioBufferList *)inInputData
                     inputTime:(AudioTimeStamp *)inInputTime
                    outputData:(AudioBufferList *)outOutputData
                    outputTime:(AudioTimeStamp *)inOutputTime
                    clientData:(VJXCoreAudioOutput *)clientData

{
    VJXAudioBuffer *sample = [[self currentSample] retain];
    if (sample) {
        @synchronized(self) {
            NSData *data = [sample data];
            if ([data length] <= outOutputData->mBuffers[0].mDataByteSize) {
                memcpy(outOutputData->mBuffers[0].mData, [data bytes], [data length]);
                outOutputData->mBuffers[0].mDataByteSize = [data length];
            }
            
        }
    }
}

@end
