//
//  JMXQtAudioCaptureLayer.m
//  JMX
//
//  Created by xant on 9/15/10.
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

#include <CoreAudio/CoreAudioTypes.h>

#define __JMXV8__
#import "JMXQtAudioCaptureEntity.h"
#include "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXQtAudioCaptureEntity);

#pragma mark -
#pragma mark Converter Callback

typedef struct CallbackContext_t {
	AudioBufferList * theConversionBuffer;
	bool wait;
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
#pragma mark JMXQtAudioGrabber
/*
 * QTKit Bridge
 */

@interface JMXQtAudioGrabber : NSObject
{
    AVCaptureDeviceInput         *input;
    AVCaptureAudioDataOutput     *captureOutput;
    AVCaptureSession             *session;
    AVCaptureDevice              *device;
    dispatch_queue_t             dispatch_queue;
    }

- (id)init;
- (void)startCapture:(JMXQtAudioCaptureEntity *)controller;
- (void)stopCapture;
@end

@implementation JMXQtAudioGrabber : NSObject

- (id)init
{
    self = [super init];
    if( self ) {

    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    
    [super dealloc];
}

- (void)startCapture:(JMXQtAudioCaptureEntity *)controller
{
    NSLog(@"QTCapture opened");
    bool ret = false;
    
    NSError *o_returnedError;
    @synchronized(self) {
        device = controller.captureDevice;
        if( !device )
        {
            NSLog(@"Can't find any audio device");
            goto error;
        }
        [device retain];

        if( [device isInUseByAnotherApplication] == YES )
        {
            NSLog(@"default capture device is exclusively in use by another application");
            goto error;
        }
        
        input = [[AVCaptureDeviceInput alloc] initWithDevice: device error:&o_returnedError];
        if( !input )
        {
            NSLog(@"can't create a valid capture input facility: %@", o_returnedError);
            goto error;
        }
        
        
        session = [[AVCaptureSession alloc] init];


        if( ![session canAddInput:input] )
        {
            NSLog(@"default audio capture device could not be added to capture session");
            goto error;
        }
        [session addInput:input];



        captureOutput = [[AVCaptureAudioDataOutput alloc] init];

        // TODO - configure the output audio format
        //[captureOutput setAudioSettings:<#(NSDictionary *)#>]

        dispatch_queue = dispatch_queue_create("jmx.videocapture", NULL);

        [captureOutput setSampleBufferDelegate:controller queue:dispatch_queue];

        if( ![session canAddOutput:captureOutput] )
        {
            NSLog(@"output could not be added to capture session (%ld)", (long)[o_returnedError code]);
            goto error;
        }

        [session addOutput:captureOutput];

        [session startRunning]; // start the capture session
        NSLog(@"audio device ready!");
        
        return;
    error:
        [input release];
    }
}

- (void)stopCapture
{
    @synchronized(self) {
        if (session) {
            [session stopRunning];
            if (input) {
                [session removeInput:input];
                [input release];
                input = NULL;
            }
           // [session removeOutput:self];
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
            /*
            if ([device isOpen])
                [device close];
             */
            [device release];
            device = NULL;
        }
    }
}

@end

#pragma mark -
#pragma mark JMXQtAudioCaptureLayer

@implementation JMXQtAudioCaptureEntity : JMXAudioCapture

@synthesize captureDevice;

+ (NSArray *)availableDevices
{
    NSMutableArray *devicesList = [[NSMutableArray alloc] init];
    NSArray *availableDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    for (AVCaptureDevice *dev in availableDevices)
        [devicesList addObject:[dev uniqueID]];
    return [devicesList autorelease];
}

+ (NSString *)defaultDevice
{
    return [[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] uniqueID];
}

- (id)init
{
    self = [super init];
    if (self) {
        grabber = [[JMXQtAudioGrabber alloc] init];
        device = [JMXQtAudioCaptureEntity defaultDevice];
        captureDevice = [[AVCaptureDevice deviceWithUniqueID:device] retain];
        if (self.active)
            [grabber startCapture:self];
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

- (void)setDevice:(NSString *)uniqueID
{
    AVCaptureDevice *dev = [AVCaptureDevice deviceWithUniqueID:uniqueID];
    if (dev) {
        if (captureDevice)
            [captureDevice release];
        captureDevice = [dev retain];
        device = [uniqueID copy];
    }
    if (active) {
        [grabber stopCapture];
        [grabber startCapture:self];
    }
        
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    //@synchronized(outputPin) {
        AudioStreamBasicDescription format;
       // AudioBufferList buffer;
        if (currentBuffer) {
            [currentBuffer release];
            currentBuffer = nil;
        }
        [[[sampleBuffer formatDescription] attributeForKey:QTFormatDescriptionAudioStreamBasicDescriptionAttribute] getValue:&format];
        AudioBufferList *buffer = [sampleBuffer audioBufferListWithOptions:(QTSampleBufferAudioBufferListOptions)QTSampleBufferAudioBufferListOptionAssure16ByteAlignment];
        
        // convert the sample to the internal format
        AudioStreamBasicDescription inputDescription = format;
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
        AudioBufferList *outputBufferList = (AudioBufferList *)malloc(sizeof(AudioBufferList));
        outputBufferList->mNumberBuffers = 1;
        outputBufferList->mBuffers[0].mDataByteSize = outputDescription.mBytesPerFrame * outputDescription.mChannelsPerFrame * framesRead;
        outputBufferList->mBuffers[0].mNumberChannels = outputDescription.mChannelsPerFrame;
        outputBufferList->mBuffers[0].mData = malloc(outputBufferList->mBuffers[0].mDataByteSize);
        callbackContext.theConversionBuffer = buffer;
        //callbackContext.wait = NO; // XXX (actually unused)
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
            currentBuffer = [[JMXAudioBuffer audioBufferWithCoreAudioBufferList:outputBufferList andFormat:&outputFormat copy:NO freeOnRelease:YES] retain];    

        if (currentBuffer)
            [outputPin deliverData:currentBuffer fromSender:self];
        [self outputDefaultSignals:CVGetCurrentHostTime()];
    //}
}

- (void)start
{
    // we don't want the extra thread (QTKit spawns already its own), 
    // so it's useless to call our super here
	//[super start];
	[grabber startCapture:self];
}

- (void)stop
{
	//[super stop];
	[grabber stopCapture];
}

@end

