//
//  VJXQtAudioCaptureLayer.m
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
#import "VJXQtAudioCaptureLayer.h"

#include <CoreAudio/CoreAudioTypes.h>
#import <QTKit/QTKit.h>


#pragma mark -
#pragma mark Converter Callback

typedef struct CallbackContext_t {
	AudioBufferList * theConversionBuffer;
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
    AudioBufferList *bufferList = ctx->theConversionBuffer;
	int i;
    for (i = 0; i < bufferList->mNumberBuffers; i++) {
        //ioData->mBuffers[i].mData = bufferList->mBuffers[i].mData;
        //ioData->mBuffers[i].mDataByteSize = bufferList->mBuffers[i].mDataByteSize;
        memcpy(&ioData->mBuffers[i], &bufferList->mBuffers[i], sizeof(AudioBuffer));
    }
    return noErr;
}

#pragma mark -
#pragma mark VJXQtAudioGrabber
/*
 * QTKit Bridge
 */

@interface VJXQtAudioGrabber : QTCaptureDecompressedAudioOutput
{
    QTCaptureDeviceInput         *input;
    QTCaptureMovieFileOutput     *captureOutput;
    QTCaptureSession             *session;
    QTCaptureDevice              *device;
}

- (id)init;
- (void)startCapture:(VJXQtAudioCaptureLayer *)controller;
- (void)stopCapture;
@end

@implementation VJXQtAudioGrabber : QTCaptureDecompressedAudioOutput

- (id)init
{
    if( self = [super init] ) {

    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    
    [super dealloc];
}

- (void)startCapture:(VJXQtAudioCaptureLayer *)controller
{
    NSLog(@"QTCapture opened");
    bool ret = false;
    
    NSError *o_returnedError;

    // XXX - supports only the default audio input for now
    device = [QTCaptureDevice defaultInputDeviceWithMediaType: QTMediaTypeSound];
    if( !device )
    {
        NSLog(@"Can't find any Video device");
        goto error;
    }
    [device retain];
    
    if( ![device open: &o_returnedError] )
    {
        NSLog(@"Unable to open the capture device (%i)", [o_returnedError code]);
        goto error;
    }
    
    if( [device isInUseByAnotherApplication] == YES )
    {
        NSLog(@"default capture device is exclusively in use by another application");
        goto error;
    }
    
    input = [[QTCaptureDeviceInput alloc] initWithDevice: device];
    if( !input )
    {
        NSLog(@"can't create a valid capture input facility");
        goto error;
    }
    
    
    session = [[QTCaptureSession alloc] init];
    
    ret = [session addInput:input error: &o_returnedError];
    if( !ret )
    {
        NSLog(@"default video capture device could not be added to capture session (%i)", [o_returnedError code]);
        goto error;
    }
    
    ret = [session addOutput:self error: &o_returnedError];
    if( !ret )
    {
        NSLog(@"output could not be added to capture session (%i)", [o_returnedError code]);
        goto error;
    }
    
    [session startRunning]; // start the capture session
    NSLog(@"Video device ready!");
    
    [self setDelegate:controller];
    return;
error:
    //[= exitQTKitOnThread];
    [input release];
    
}

- (void)stopCapture
{
    if (session) {
        [session stopRunning];
        if (input) {
            [session removeInput:input];
            [input release];
            input = NULL;
        }
        [session removeOutput:self];
        [session release];
        session = nil;
    }
    /*
     if (output) {
     [output release];
     output = NULL;
     }
     */
    if (device) {
        if ([device isOpen])
            [device close];
        [device release];
        device = NULL;
    }
    
}

@end

#pragma mark -
#pragma mark VJXQtAudioCaptureLayer

@implementation VJXQtAudioCaptureLayer : VJXEntity

- (id)init
{
    if (self == [super init]) {
        grabber = [[VJXQtAudioGrabber alloc] init];
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        // Set the client format to 32bit float data
        // Maintain the channel count and sample rate of the original source format
        outputFormat.mSampleRate = 44100;
        outputFormat.mChannelsPerFrame = 1;
        outputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        outputFormat.mFormatID = kAudioFormatLinearPCM;
        outputFormat.mBytesPerPacket = 4 * outputFormat.mChannelsPerFrame;
        outputFormat.mFramesPerPacket = 1;
        outputFormat.mBytesPerFrame = 4 * outputFormat.mChannelsPerFrame;
        outputFormat.mBitsPerChannel = 32;
    } else {
        [self dealloc];
        return nil;
    }
    return self;
}

- (void)dealloc
{
	if (grabber) {
		[grabber release];
        grabber = nil;
    }
	[super dealloc];
}

- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputAudioSampleBuffer:(QTSampleBuffer *)sampleBuffer
                                                             fromConnection:(QTCaptureConnection *)connection
{
    //@synchronized(outputPin) {
        AudioStreamBasicDescription format;
       // AudioBufferList buffer;
        if (currentBuffer)
            [currentBuffer release];
        [[[sampleBuffer formatDescription] attributeForKey:QTFormatDescriptionAudioStreamBasicDescriptionAttribute] getValue:&format];
        AudioBufferList *buffer = [sampleBuffer audioBufferListWithOptions:(QTSampleBufferAudioBufferListOptions)QTSampleBufferAudioBufferListOptionAssure16ByteAlignment];
        
        
        AudioStreamBasicDescription inputDescription = format;
#if 0
        AudioStreamBasicDescription outputDescription = outputFormat;
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
        UInt32 framesRead = buffer->mBuffers[0].mDataByteSize / format.mBytesPerFrame / buffer->mBuffers[0].mNumberChannels;
        AudioBufferList *outputBufferList = malloc(sizeof(AudioBufferList));
        outputBufferList->mNumberBuffers = 1;
        outputBufferList->mBuffers[0].mDataByteSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * framesRead;
        outputBufferList->mBuffers[0].mNumberChannels = outputDescription.mChannelsPerFrame;
        outputBufferList->mBuffers[0].mData = malloc(outputBufferList->mBuffers[0].mDataByteSize);
        callbackContext.theConversionBuffer = buffer;
        callbackContext.wait = NO; // XXX (actually unused)
        if (inputDescription.mSampleRate == outputDescription.mSampleRate &&
            inputDescription.mBytesPerFrame == outputDescription.mBytesPerFrame) {
            err = AudioConverterConvertBuffer (
                                               converter,
                                               buffer->mBuffers[0].mDataByteSize,
                                               buffer->mBuffers[0].mData,
                                               &outputBufferList->mBuffers[0].mDataByteSize,
                                               outputBufferList->mBuffers[0].mData
                                               );
        } else {
            err = AudioConverterFillComplexBuffer ( converter, _FillComplexBufferProc, &callbackContext, &framesRead, outputBufferList, NULL );
        }
        if (err == noErr)
            currentBuffer = [[VJXAudioBuffer audioBufferWithCoreAudioBufferList:outputBufferList andFormat:&outputFormat copy:NO freeOnRelease:YES] retain];    
#else
        currentBuffer = [[VJXAudioBuffer audioBufferWithCoreAudioBufferList:buffer andFormat:&inputDescription copy:YES freeOnRelease:YES] retain];    
#endif
        if (currentBuffer)
            [outputPin deliverSignal:currentBuffer fromSender:self];
        [self outputDefaultSignals:CVGetCurrentHostTime()];
    //}
}

- (void)start
{
    // we don't want the a thread, 
    // so it's useless to call our super here
	//[super start];
	[grabber startCapture:self];
}

- (void)stop
{
	//[super stop];
	[grabber stopCapture];
}

#pragma mark -
#pragma mark NSCoding

- (void)encodeWithCoder:(NSCoder *)aCoder
{
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    return self;
}

- (void)tick:(uint64_t)timeStamp
{
    [self outputDefaultSignals:timeStamp];
}

@end

