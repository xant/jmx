//
//  VJXCoreAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXCoreAudioOutput.h"


@implementation VJXCoreAudioOutput

- (id)init
{
    outputDevice = [[VJXAudioDevice defaultOutputDevice] retain];
    [outputDevice setIOTarget:self 
                 withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
               withClientData:self];
    // start the device
    [outputDevice deviceStart];
    format = [[outputDevice streamDescriptionForChannel:0 forDirection:kVJXAudioOutput] retain];
    [outputDevice setDelegate:(VJXCoreAudioOutput *)self];
    [super init]; // we know that our parent won't never return nil and we need
                  // its initializer to be run after we have set the format
    return self;
}

- (void)dealloc
{
    if (outputDevice) {
        [outputDevice release];
    }
    [super dealloc];
}

- (void)provideSamplesToDevice:(VJXAudioDevice *)device
                     timeStamp:(AudioTimeStamp *)timeStamp
                     inputData:(AudioBufferList *)inInputData
                     inputTime:(AudioTimeStamp *)inInputTime
                    outputData:(AudioBufferList *)outOutputData
                    outputTime:(AudioTimeStamp *)inOutputTime
                    clientData:(VJXCoreAudioOutput *)clientData

{
    VJXAudioBuffer *sample = [self currentSample];

    if (sample) {
        int i;
        for (i = 0; i < outOutputData->mNumberBuffers; i++) {
            SInt32 bytesToCopy = MIN(outOutputData->mBuffers[i].mDataByteSize, sample.bufferList->mBuffers[i].mDataByteSize);
            if (outOutputData->mBuffers[i].mData && sample.bufferList->mNumberBuffers > i) {
                bcopy(sample.bufferList->mBuffers[i].mData,
                      outOutputData->mBuffers[i].mData,
                       bytesToCopy);
                outOutputData->mBuffers[i].mDataByteSize = bytesToCopy;
                outOutputData->mBuffers[i].mNumberChannels = sample.bufferList->mBuffers[i].mNumberChannels;
            }
        }
    } else {
        //NSLog(@"NO FRAME");
    }
}

- (void)audioDeviceClockSourceDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection
{
}

- (void)audioDeviceSomethingDidChange:(VJXAudioDevice *)device
{
}

- (void)audioDeviceDidOverload:(VJXAudioDevice *)device
{
    NSLog(@"Overload!");
}

@end
