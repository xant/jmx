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
    if (self = [super init]) {
        [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:"];
        ringBuffer = [[NSMutableArray alloc] init];
        converter = NULL;
        format = nil; // must be set by superclasses
    }
    return self;
}

- (void)newSample:(VJXAudioBuffer *)buffer
{
    if (!buffer)
        return;
    if (!format) {
        NSLog(@"No output format! (%@)", self); // subclasses should define it at initialization time
        return;
    }
    AudioStreamBasicDescription inputDescription = buffer.format.audioStreamBasicDescription;
    AudioStreamBasicDescription outputDescription = format.audioStreamBasicDescription;
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
    @synchronized(ringBuffer) {
        OSStatus err = noErr;
        CallbackContext callbackContext;
        UInt32 framesRead = [buffer numFrames];
        AudioBufferList *outputBufferList = calloc(sizeof(AudioBufferList), 1);
        outputBufferList->mNumberBuffers = 1;
        outputBufferList->mBuffers[0].mDataByteSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * framesRead;
        outputBufferList->mBuffers[0].mNumberChannels = outputDescription.mChannelsPerFrame;
        outputBufferList->mBuffers[0].mData = calloc(outputBufferList->mBuffers[0].mDataByteSize, 1);
        callbackContext.theConversionBuffer = buffer;
        callbackContext.wait = YES; // XXX
        //UInt32 outputChannels = [buffer numChannels];
        //if (inputDescription.mSampleRate != outputDescription.mSampleRate) {
            err = AudioConverterFillComplexBuffer ( converter, _FillComplexBufferProc, &callbackContext, &framesRead, outputBufferList, NULL );
        /*} else {
            err = AudioConverterConvertBuffer (
                                          converter,
                                          buffer.buffer.mDataByteSize,
                                          buffer.buffer.mData,
                                          &outputBufferList->mBuffers[0].mDataByteSize,
                                          outputBufferList->mBuffers[0].mData
                                        );
        } */
        if (err == noErr)
            [ringBuffer addObject:[VJXAudioBuffer audioBufferWithCoreAudioBuffer:&outputBufferList->mBuffers[0] andFormat:&outputDescription]];
        free(outputBufferList->mBuffers[0].mData);
        free(outputBufferList);
    }
}

- (VJXAudioBuffer *)currentSample
{
    VJXAudioBuffer *oldestSample = nil;
    @synchronized(ringBuffer) {
        if ([ringBuffer count]) {
            oldestSample = [[ringBuffer objectAtIndex:0] retain];
            [ringBuffer removeObjectAtIndex:0];
        }
    }
    return [oldestSample autorelease];
}

- (void)dealloc
{
    if (ringBuffer)
        [ringBuffer release];
    [super dealloc];
}

@end
