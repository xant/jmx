//
//  VJXAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/14/10.
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

#import "VJXAudioOutput.h"
#import "VJXAudioBuffer.h"
#import "VJXAudioFormat.h"
#import <CoreAudio/CoreAudioTypes.h>

#define kVJXAudioOutputPreBufferMaxSize 30
#define kVJXAudioOutputPreBufferMinSize 15

typedef struct CallbackContext_t {
	VJXAudioBuffer * theConversionBuffer;
	Boolean wait;
    UInt32 offset;
} CallbackContext;

static OSStatus _FillComplexBufferProc (
                                        AudioConverterRef aConveter,
                                        UInt32 * ioNumberDataPackets,
                                        AudioBufferList * ioData,
                                        AudioStreamPacketDescription ** outDataPacketDescription,
                                        void * inUserData
                                        )
{
	CallbackContext * ctx = inUserData;
	
	return [ctx->theConversionBuffer fillComplexBuffer:ioData countPointer:ioNumberDataPackets waitForData:ctx->wait offset:ctx->offset];
}

@implementation VJXAudioOutput
- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:"];
        currentSamplePin = [self registerOutputPin:@"currentSample" withType:kVJXAudioPin];
        converter = NULL;
        outputDescription = format.audioStreamBasicDescription;
        outputBufferList = calloc(sizeof(AudioBufferList), 1);
        outputBufferList->mNumberBuffers = 1;
        chunkSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * kVJXAudioOutputMaxFrames;
        outputBufferList->mBuffers[0].mDataByteSize = chunkSize;
        outputBufferList->mBuffers[0].mNumberChannels = outputDescription.mChannelsPerFrame;
        // preallocate the buffer used for outputsamples
        convertedBuffer = malloc(outputBufferList->mBuffers[0].mDataByteSize*kVJXAudioOutputConvertedBufferSize);
        convertedOffset = 0;
        needsPrefill = YES;
        rOffset = wOffset = 0;
        memset(samples, 0, sizeof(samples));
    }
    return self;
}


- (void)newSample:(VJXAudioBuffer *)buffer
{
    //VJXAudioBuffer *newSample = nil;

    if (!buffer)
        return;
#if 0 // disable conversion for now 
    // sample needs to be converted before being sent to the audio device
    // the output format depends on the output device and could be different from the 
    // one used internally (44Khz stereo float32 interleaved)
    
    AudioStreamBasicDescription inputDescription = buffer.format.audioStreamBasicDescription;
    if (!converter) { // create on first use
        if ( noErr != AudioConverterNew ( &inputDescription, &outputDescription, &converter )) {
            converter = NULL; // just in case
            // TODO - Error Messages
            return;
        } else {
            
            UInt32 primeMethod = kConverterPrimeMethod_None;
            UInt32 srcQuality = kAudioConverterQuality_Max;
            (void) AudioConverterSetProperty ( converter, kAudioConverterPrimeMethod, sizeof(UInt32), &primeMethod );
            (void) AudioConverterSetProperty ( converter, kAudioConverterSampleRateConverterQuality, sizeof(UInt32), &srcQuality );
        }
    } else {
        // TODO - check if inputdescription or outputdescription have changed and, 
        //        if that's the case, reset the converter accordingly
    }
    OSStatus err = noErr;
    CallbackContext callbackContext;
    UInt32 framesRead = [buffer numFrames];
    // TODO - check if framesRead is > 512
    outputBufferList->mBuffers[0].mDataByteSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * framesRead;
    outputBufferList->mBuffers[0].mData = convertedBuffer+(convertedOffset++%kVJXAudioOutputConvertedBufferSize)*chunkSize;
    callbackContext.theConversionBuffer = buffer;
    callbackContext.wait = NO; // XXX (actually unused)
    //UInt32 outputChannels = [buffer numChannels];
    if (inputDescription.mSampleRate == outputDescription.mSampleRate &&
        inputDescription.mBytesPerFrame == outputDescription.mBytesPerFrame) {
        err = AudioConverterConvertBuffer (
                                           converter,
                                           buffer.bufferList->mBuffers[0].mDataByteSize,
                                           buffer.bufferList->mBuffers[0].mData,
                                           &outputBufferList->mBuffers[0].mDataByteSize,
                                           outputBufferList->mBuffers[0].mData
                                           );
    } else {
        err = AudioConverterFillComplexBuffer ( converter, _FillComplexBufferProc, &callbackContext, &framesRead, outputBufferList, NULL );
    }
    if (err != noErr) {
        samples[wOffset++%kVJXAudioOutputSamplesBufferCount] = [[VJXAudioBuffer audioBufferWithCoreAudioBufferList:outputBufferList andFormat:&inputDescription copy:NO freeOnRelease:NO] retain];
    }
#else
    VJXAudioBuffer *previousSample;
    previousSample = samples[wOffset%kVJXAudioOutputSamplesBufferCount];
    samples[wOffset++%kVJXAudioOutputSamplesBufferCount] = [buffer retain];
    // let's have the buffer released next time the active pool is drained
    // we want to return as soon as possible
    if (previousSample)
        [previousSample autorelease];
#endif
    if (wOffset > kVJXAudioOutputSamplesBufferPrefillCount)
        needsPrefill = NO;
}

// this will only be called by the audiooutput mainthred
- (VJXAudioBuffer *)currentSample
{
    //NSLog(@"r: %d - w: %d", rOffset % kVJXAudioOutputSamplesBufferCount , wOffset % kVJXAudioOutputSamplesBufferCount);
    VJXAudioBuffer *sample = nil;
    if (rOffset < wOffset && !needsPrefill) {
        sample = samples[rOffset++%kVJXAudioOutputSamplesBufferCount];
    }
    return sample;
}

- (void)dealloc
{
    if (format)
        [format dealloc];

    while (rOffset < wOffset) 
        [samples[rOffset++%kVJXAudioOutputSamplesBufferCount] release];
    if (convertedBuffer)
        free(convertedBuffer);
    [super dealloc];
}

@end
