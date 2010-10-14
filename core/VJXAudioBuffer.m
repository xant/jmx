//
//  VJXAudioBuffer.m
//  VeeJay
//
//  Created by xant on 9/15/10.
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

#import "VJXAudioBuffer.h"
#import "VJXAudioFormat.h"

@implementation VJXAudioBuffer

@synthesize bufferList, format;

+ (id)audioBufferWithCoreAudioBuffer:(AudioBuffer *)audioBuffer andFormat:(AudioStreamBasicDescription *)audioFormat
{
    return [[[VJXAudioBuffer alloc] initWithCoreAudioBuffer:audioBuffer andFormat:audioFormat] autorelease];
}

+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat
{
    return [[[VJXAudioBuffer alloc] initWithCoreAudioBufferList:audioBufferList andFormat:audioFormat] autorelease];
}

+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree
{
    return [[[VJXAudioBuffer alloc] initWithCoreAudioBufferList:audioBufferList andFormat:audioFormat copy:wantsCopy freeOnRelease:wantsFree] autorelease];
}

- (id)initWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree
{
    if (self = [super init]) {
        int i;
        freeOnRelease = wantsFree;
        if (audioFormat)
            format = [[VJXAudioFormat formatWithAudioStreamDescription:*audioFormat] retain];
        if (wantsCopy) {
            bufferList = calloc(1, sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(audioBufferList->mNumberBuffers-1)));
            bufferList->mNumberBuffers = audioBufferList->mNumberBuffers;
            for (i = 0; i < bufferList->mNumberBuffers; i++) {
                bufferList->mBuffers[i].mDataByteSize = audioBufferList->mBuffers[i].mDataByteSize;
                bufferList->mBuffers[i].mNumberChannels = audioBufferList->mBuffers[i].mNumberChannels;
                bufferList->mBuffers[i].mData = malloc(audioBufferList->mBuffers[i].mDataByteSize);
                memcpy(bufferList->mBuffers[i].mData, audioBufferList->mBuffers[i].mData, audioBufferList->mBuffers[i].mDataByteSize);
            }
        } else {
            bufferList = audioBufferList;
        }
    }
    return self;
}

- (id)initWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat
{
    return [self initWithCoreAudioBufferList:audioBufferList andFormat:audioFormat copy:YES freeOnRelease:YES];
}

- (id)initWithCoreAudioBuffer:(AudioBuffer *)audioBuffer andFormat:(AudioStreamBasicDescription *)audioFormat
{
    AudioBufferList list;
    list.mNumberBuffers = 1;
    memcpy(&list.mBuffers[0], audioBuffer, sizeof(AudioBuffer));
    return [self initWithCoreAudioBufferList:&list andFormat:audioFormat];

}

- (void)dealloc
{
    int i;
    if (deinterleaved) {
        [deinterleaved removeAllObjects];
        [deinterleaved release];
    }
    if (freeOnRelease) {
        for (i = 0; i < bufferList->mNumberBuffers; i++) {
            if (bufferList->mBuffers[i].mData)
                free(bufferList->mBuffers[i].mData);
        }
        free(bufferList);
    }
    if (format)
        [format release];

    [super dealloc];
}

- (UInt32)numBuffers
{
    return bufferList->mNumberBuffers;
}

- (NSData *)dataForBuffer:(UInt32)index
{
    if (index < bufferList->mNumberBuffers)
        return [NSData dataWithBytesNoCopy:bufferList->mBuffers[index].mData
                                    length:bufferList->mBuffers[index].mDataByteSize
                              freeWhenDone:NO];
    return nil;
}

- (NSData *)data
{
    return [self dataForBuffer:0];
}

- (NSUInteger)numFrames
{
    return bufferList->mBuffers[0].mDataByteSize / format.audioStreamBasicDescription.mBytesPerFrame / bufferList->mBuffers[0].mNumberChannels;
}

- (NSUInteger)bytesPerFrame
{
    return format.audioStreamBasicDescription.mBytesPerFrame;
}

- (NSUInteger)bitsPerChannel
{
    return format.audioStreamBasicDescription.mBitsPerChannel;
}

- (NSUInteger)channelsPerFrame
{
    return format.audioStreamBasicDescription.mChannelsPerFrame;
}

- (NSUInteger)sampleRate
{
    return format.audioStreamBasicDescription.mSampleRate;
}

- (NSUInteger)numChannels
{
    return [self channelsPerFrame];
}

- (OSStatus)fillComplexBuffer:(AudioBufferList *)ioData countPointer:(UInt32 *)ioNumberFrames waitForData:(Boolean)wait offset:(UInt32)offset
{
	unsigned i;
	unsigned framesInBuffer = [self numFrames];
	
	*ioNumberFrames = MIN ( *ioNumberFrames, framesInBuffer );

    for (i = 0; i < bufferList->mNumberBuffers; i++) {
        ioData->mBuffers[i].mData = bufferList->mBuffers[i].mData;
        ioData->mBuffers[i].mDataByteSize = bufferList->mBuffers[i].mDataByteSize;
        //memcpy(&ioData->mBuffers[i], &bufferList->mBuffers[i], sizeof(AudioBuffer));
    }

    return noErr;
}

@end
