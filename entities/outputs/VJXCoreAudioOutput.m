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
    if (self == [super init]) {
        outputDevice = [[VJXAudioDevice defaultOutputDevice] retain];
        [outputDevice setIOTarget:self withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:) withClientData:self];
        [outputDevice deviceStart];
        format = [[outputDevice streamDescriptionForChannel:0 forDirection:kVJXAudioOutput] retain];
    }
    return self;
}

- (void)dealloc
{
    if (outputDevice) {
        [outputDevice deviceStop];
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
