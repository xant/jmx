//
//  VJXQtCaptureLayer.m
//  VeeJay
//
//  Created by xant on 9/13/10.
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

#import "VJXQtCaptureLayer.h"
#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>

#define VJX_GRABBER_WIDTH_MAX 640
#define VJX_GRABBER_HEIGHT_MAX 480

/* Coming from Apple sample code */

/*
 * QTKit Bridge
 */

@interface VJXQtGrabber : QTCaptureDecompressedVideoOutput
{
    QTCaptureDeviceInput         *input;
    QTCaptureMovieFileOutput     *captureOutput;
    QTCaptureSession             *session;
    QTCaptureDevice              *device;
    int                          width;
    int                          height;
}

- (id)init;
- (void)startCapture:(VJXQtCaptureLayer *)controller;
- (void)stopCapture;
- (NSSize)size;
@end

@implementation VJXQtGrabber : QTCaptureDecompressedVideoOutput

- (id)init
{
    if( self = [super init] ) {
        width = 352;
        height = 288;
    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    
    [super dealloc];
}

- (void)startCapture:(VJXQtCaptureLayer *)controller
{
    NSLog(@"QTCapture opened");
    bool ret = false;
    
    NSError *o_returnedError;
    width = controller.size.width;
    height = controller.size.height;
    /* Hack - using max resolution seems to lower cpu consuption for some reason */
    int h = (height < VJX_GRABBER_HEIGHT_MAX)
            ? height
            : VJX_GRABBER_HEIGHT_MAX;
    int w = (width < VJX_GRABBER_WIDTH_MAX)
            ? width
            : VJX_GRABBER_WIDTH_MAX;
    device = [QTCaptureDevice defaultInputDeviceWithMediaType: QTMediaTypeVideo];
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
    
    [self setPixelBufferAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:h], kCVPixelBufferHeightKey,
                                     [NSNumber numberWithInt:w], kCVPixelBufferWidthKey, 
                                     [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],
                                     (id)kCVPixelBufferPixelFormatTypeKey, nil]];
    
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

- (NSSize)size
{
    return NSMakeSize(width, height);
}

@end


@implementation VJXQtCaptureLayer : VJXLayer

- (void)captureOutput:(QTCaptureOutput *)captureOutput 
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
       fromConnection:(QTCaptureConnection *)connection
{
    @synchronized (self) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [[CIImage imageWithCVImageBuffer:videoFrame] retain];
    }
}

- (id)init
{
    if (self == [super init]) {
        grabber = [[VJXQtGrabber alloc] init];
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
	[super start];
	[grabber startCapture:self];
}

- (void)stop
{
	[super stop];
	[grabber stopCapture];
}

- (void)setSize:(VJXSize *)newSize
{
    [super setSize:newSize];
    [grabber setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:newSize.height], kCVPixelBufferHeightKey,
                                      [NSNumber numberWithInt:newSize.width], kCVPixelBufferWidthKey,
                                      [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],
                                      (id)kCVPixelBufferPixelFormatTypeKey, nil]];
}

@end
