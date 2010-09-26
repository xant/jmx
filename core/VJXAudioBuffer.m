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

- (id)initWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat
{
    if (self = [super init]) {
        int i;
        uint8_t *deinterleavedBuffer = NULL;
        if (audioFormat)
            format = [[VJXAudioFormat formatWithAudioStreamDescription:*audioFormat] retain];
        bufferList = calloc(1, sizeof(AudioBufferList)+(sizeof(AudioBuffer)*(audioBufferList->mNumberBuffers-1)));
        bufferList->mNumberBuffers = audioBufferList->mNumberBuffers;
        for (i = 0; i < bufferList->mNumberBuffers; i++) {
            bufferList->mBuffers[i].mDataByteSize = audioBufferList->mBuffers[i].mDataByteSize;
            bufferList->mBuffers[i].mNumberChannels = audioBufferList->mBuffers[i].mNumberChannels;
            bufferList->mBuffers[i].mData = malloc(audioBufferList->mBuffers[i].mDataByteSize);
            memcpy(bufferList->mBuffers[i].mData, audioBufferList->mBuffers[i].mData, audioBufferList->mBuffers[i].mDataByteSize);
            
            // XXX - unsure if it's really necessary to always de-interleave the buffers (we could do it only if/when necessary)
            if (bufferList->mBuffers[i].mNumberChannels > 1) { // de-interleave the audio frames (we could need that later)
                int j;
                UInt32 numFrames = bufferList->mBuffers[i].mDataByteSize / format.audioStreamBasicDescription.mBytesPerFrame / bufferList->mBuffers[i].mNumberChannels;
                deinterleavedBuffer = calloc(bufferList->mBuffers[i].mDataByteSize, 1);
                uint8_t *channels[bufferList->mBuffers[i].mNumberChannels];
                
                // set pointers to the de-interleaved buffer for each channel
                for (j = 0; j < bufferList->mBuffers[i].mNumberChannels; j++) {
                    channels[j] = ((uint8_t *)deinterleavedBuffer)+((bufferList->mBuffers[i].mDataByteSize/bufferList->mBuffers[i].mNumberChannels)*j);
                }
                
                // and then fill them up
                for (j = 0; j < numFrames; j++) {
                    uint8_t *frame = ((uint8_t *)bufferList->mBuffers[i].mData)+(j*audioFormat->mBytesPerFrame*bufferList->mBuffers[i].mNumberChannels);
                    memcpy(channels[0]+j, frame, audioFormat->mBytesPerFrame*bufferList->mBuffers[i].mNumberChannels);
                    memcpy(channels[1]+j, frame+audioFormat->mBytesPerFrame*bufferList->mBuffers[i].mNumberChannels, audioFormat->mBytesPerFrame*bufferList->mBuffers[i].mNumberChannels);
                }
                [deinterleaved addObject:[NSData dataWithBytesNoCopy:deinterleavedBuffer
                                                              length:bufferList->mBuffers[i].mDataByteSize
                                                        freeWhenDone:YES]];
            }
        }
    }
    return self;
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
    for (i = 0; i < bufferList->mNumberBuffers; i++) {
        if (bufferList->mBuffers[i].mData)
            free(bufferList->mBuffers[i].mData);
    }
    free(bufferList);
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
