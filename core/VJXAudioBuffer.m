//
//  VJXAudioBuffer.m
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioBuffer.h"


@implementation VJXAudioBuffer

+ (id)audioBufferWithCoreAudioBuffer:(AudioBuffer *)audioBuffer andFormat:(AudioStreamBasicDescription *)audioFormat
{
    return [[[VJXAudioBuffer alloc] initWithCoreAudioBuffer:audioBuffer andFormat:audioFormat] autorelease];
}

- (id)initWithCoreAudioBuffer:(AudioBuffer *)audioBuffer andFormat:(AudioStreamBasicDescription *)audioFormat
{
    if (self = [super init]) {
        buffer.mDataByteSize = audioBuffer->mDataByteSize;
        buffer.mNumberChannels = audioBuffer->mNumberChannels;
        buffer.mData = malloc(audioBuffer->mDataByteSize);
        memcpy(buffer.mData, audioBuffer->mData, audioBuffer->mDataByteSize);
        if (audioFormat)
            memcpy(&format, audioFormat, sizeof(AudioStreamBasicDescription));
        // success
        /*
         *outDataSize = (ALsizei)dataSize;
         *outDataFormat = (theOutputFormat.mChannelsPerFrame > 1) ? AL_FORMAT_STEREO16 : AL_FORMAT_MONO16;
         *outSampleRate = (ALsizei)theOutputFormat.mSampleRate;
         */
    }
    return self;
}

- (void)dealloc
{
    if (buffer.mData)
        free(buffer.mData);
    [super dealloc];
}

- (NSData *)data
{
    return [NSData dataWithBytesNoCopy:buffer.mData length:buffer.mDataByteSize freeWhenDone:NO];
}

- (NSUInteger)numFrames
{
    return buffer.mDataByteSize / format.mBytesPerFrame;
}

- (NSUInteger)bytesPerFrame
{
    return format.mBytesPerFrame;
}

- (NSUInteger)bitsPerChannel
{
    return format.mBitsPerChannel;
}

- (NSUInteger)channelsPerFrame
{
    return format.mChannelsPerFrame;
}

- (NSUInteger)sampleRate
{
    return format.mSampleRate;
}

- (NSUInteger)numChannels
{
    return [self channelsPerFrame];
}

- (OSStatus)fillComplexBuffer:(AudioBufferList *)ioData countPointer:(UInt32 *)ioNumberFrames waitForData:(Boolean)wait offset:(UInt32)offset
{
	unsigned i;
	//unsigned channelsThisBuffer;
	unsigned framesToCopy;
	unsigned framesInBuffer = [self numFrames];
    //nsigned framesCopied;
	
	framesToCopy = MIN ( *ioNumberFrames, framesInBuffer );
	
    for (i = 0; i < framesToCopy; i++) {
        ioData->mBuffers[i].mDataByteSize = framesToCopy * buffer.mNumberChannels * format.mBytesPerFrame;
        ioData->mBuffers[0].mData = buffer.mData + offset;
    }
    ioData->mNumberBuffers = framesToCopy;
    *ioNumberFrames = framesToCopy;
    return noErr;
}

@end
