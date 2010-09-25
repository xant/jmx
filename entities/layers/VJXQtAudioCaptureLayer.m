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


@implementation VJXQtAudioCaptureLayer : VJXEntity

- (void)captureOutput:(QTCaptureOutput *)captureOutput didOutputAudioSampleBuffer:(QTSampleBuffer *)sampleBuffer
                                                             fromConnection:(QTCaptureConnection *)connection
{
    @synchronized(outputPin) {
        AudioStreamBasicDescription format;
        AudioBufferList buffer;
        if (currentBuffer)
            [currentBuffer release];
        [[[sampleBuffer formatDescription] attributeForKey:QTFormatDescriptionAudioStreamBasicDescriptionAttribute] getValue:&format];
        buffer.mNumberBuffers = 1;
        buffer.mBuffers[0].mDataByteSize = [sampleBuffer lengthForAllSamples];
        buffer.mBuffers[0].mNumberChannels = format.mChannelsPerFrame;
        buffer.mBuffers[0].mData = [sampleBuffer bytesForAllSamples];
        currentBuffer = [[VJXAudioBuffer audioBufferWithCoreAudioBuffer:&buffer.mBuffers[0] andFormat:&format] retain];
        
        [outputPin deliverSignal:currentBuffer fromSender:self];
        [self outputDefaultSignals:CVGetCurrentHostTime()];
    }
}

- (id)init
{
    if (self == [super init]) {
        grabber = [[VJXQtAudioGrabber alloc] init];
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
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
    //[aCoder encodeObject:NSStringFromSize([grabber size]) forKey:@"VJXQtVideoCaptureLayerGrabberSize"];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [self init];
    //[self setSize:[VJXSize sizeWithNSSize:NSSizeFromString([aDecoder decodeObjectForKey:@"VJXQtVideoCaptureLayerGrabberSize"])]];
    return self;
}


@end

