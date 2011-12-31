//
//  JMXAudioOutput.m
//  JMX
//
//  Created by xant on 9/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <AudioToolbox/AudioConverter.h>
#import <CoreAudio/CoreAudioTypes.h>
#import "JMXAudioBuffer.h"
#import "JMXAudioFormat.h"
#define __JMXV8__ 1
#import "JMXAudioOutput.h"

#define kJMXAudioOutputPreBufferMaxSize 30
#define kJMXAudioOutputPreBufferMinSize 15

typedef struct CallbackContext_t {
	JMXAudioBuffer * theConversionBuffer;
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
	CallbackContext * ctx = (CallbackContext *)inUserData;
	
	return [ctx->theConversionBuffer fillComplexBuffer:ioData countPointer:ioNumberDataPackets offset:ctx->offset];
}

@implementation JMXAudioOutput
- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kJMXAudioPin andSelector:@"newSample:"];
        currentSamplePin = [self registerOutputPin:@"currentSample" withType:kJMXAudioPin];
        converter = NULL;
        outputDescription = format.audioStreamBasicDescription;
        outputBufferList = (AudioBufferList *)calloc(sizeof(AudioBufferList), 1);
        outputBufferList->mNumberBuffers = 1;
        chunkSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * kJMXAudioOutputMaxFrames;
        outputBufferList->mBuffers[0].mDataByteSize = chunkSize;
        outputBufferList->mBuffers[0].mNumberChannels = outputDescription.mChannelsPerFrame;
        // preallocate the buffer used for outputsamples
        convertedBuffer = malloc(outputBufferList->mBuffers[0].mDataByteSize*kJMXAudioOutputConvertedBufferSize);
        convertedOffset = 0;
        needsPrefill = YES;
        rOffset = wOffset = 0;
        memset(samples, 0, sizeof(samples));
    }
    return self;
}


- (void)newSample:(JMXAudioBuffer *)buffer
{
    //JMXAudioBuffer *newSample = nil;

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
    outputBufferList->mBuffers[0].mData = convertedBuffer+(convertedOffset++%kJMXAudioOutputConvertedBufferSize)*chunkSize;
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
        JMXAudioBuffer *previousSample;
        @synchronized(samples) {
            previousSample = samples[wOffset%kJMXAudioOutputSamplesBufferCount];
            samples[wOffset++%kJMXAudioOutputSamplesBufferCount] = [[JMXAudioBuffer audioBufferWithCoreAudioBufferList:outputBufferList andFormat:&inputDescription copy:YES freeOnRelease:YES] retain];
        }
        // let's have the buffer released next time the active pool is drained
        // we want to return as soon as possible
        if (previousSample)
            [previousSample release];
    }
#else
    JMXAudioBuffer *previousSample;
    [writersLock lock];
    previousSample = samples[wOffset%kJMXAudioOutputSamplesBufferCount];
    samples[wOffset++%kJMXAudioOutputSamplesBufferCount] = [buffer retain];
    [writersLock unlock];
    // let's have the buffer released next time the active pool is drained
    // we want to return as soon as possible
    if (previousSample)
        [previousSample release];
#endif
    if (wOffset > kJMXAudioOutputSamplesBufferPrefillCount)
        needsPrefill = NO;
}

// this will only be called by the audio-output mainthread
// so we can avoid using locks
- (JMXAudioBuffer *)currentSample
{
    //NSLog(@"r: %d - w: %d", rOffset % kJMXAudioOutputSamplesBufferCount , wOffset % kJMXAudioOutputSamplesBufferCount);
    JMXAudioBuffer *sample = nil;
    if (rOffset < wOffset && !needsPrefill) {
        @synchronized(self) {
            sample = samples[rOffset%kJMXAudioOutputSamplesBufferCount];
            samples[rOffset++%kJMXAudioOutputSamplesBufferCount] = nil;
        }
    }
    return [sample autorelease];
}

- (void)dealloc
{
    if (format)
        [format dealloc];
    if (writersLock)
        [writersLock release];
    for (int i = 0; i < kJMXAudioOutputSamplesBufferCount; i++) {
        if (samples[i])
            [samples[i] release];
    }
    if (convertedBuffer)
        free(convertedBuffer);
    [super dealloc];
}

#pragma mark V8
using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    v8::Persistent<FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);  
    objectTemplate->SetClassName(String::New("AudioOutput"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    NSLog(@"JMXAudioOutput objectTemplate created");
    return objectTemplate;
}

@end
