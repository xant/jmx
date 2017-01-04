//
//  JMXQtVideoCaptureEntity.m
//  JMX
//
//  Created by xant on 9/13/10.
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

#include <OpenGL/OpenGL.h>
#include <OpenGL/gl.h>
#import <Cocoa/Cocoa.h>
#define __JMXV8__
#import "JMXQtVideoCaptureEntity.h"
#include "JMXScript.h"

#define JMX_GRABBER_WIDTH_MAX 640
#define JMX_GRABBER_HEIGHT_MAX 480

/*
 * QTKit Bridge
 */

JMXV8_EXPORT_NODE_CLASS(JMXQtVideoCaptureEntity);
@interface JMXQtVideoGrabber : NSObject
{
    AVCaptureDeviceInput         *input;
    AVCaptureVideoDataOutput     *captureOutput;
    AVCaptureSession             *session;
    AVCaptureDevice              *device;
    int                          width;
    int                          height;
    dispatch_queue_t             dispatch_queue;
}

- (id)init;
- (void)startCapture:(JMXQtVideoCaptureEntity *)controller;
- (void)stopCapture;
- (void)setPixelBufferAttributes:(NSDictionary *)attributes;
- (NSSize)size;
@end

@implementation JMXQtVideoGrabber : NSObject

- (id)init
{
    self = [super init];
    if(self) {
        width = 640;
        height = 480;
        session = nil;
        input = nil;
    }
    return self;
}

- (void)dealloc
{
    [self stopCapture];
    
    [super dealloc];
}

/* Coming from Apple sample code */
- (void)startCapture:(JMXQtVideoCaptureEntity *)controller
{
    if (session) // a session is already running
        return;

    NSLog(@"QTCapture opened");
    bool ret = false;
    
    NSError *o_returnedError;
    width = controller.size.width;
    height = controller.size.height;
    /* Hack - using max resolution seems to lower cpu consuption for some reason */
    int h = (height < JMX_GRABBER_HEIGHT_MAX)
            ? height
            : JMX_GRABBER_HEIGHT_MAX;
    int w = (width < JMX_GRABBER_WIDTH_MAX)
            ? width
            : JMX_GRABBER_WIDTH_MAX;
    
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ( !device )
    {
        NSLog(@"Can't find any Video device");
        goto error;
    }

    if ([device isInUseByAnotherApplication] == YES)
    {
        NSLog(@"default capture device is exclusively in use by another application");
        goto error;
    }

    input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&o_returnedError];
    if ( !input )
    {
        NSLog(@"can't create a valid capture input facility: %@", o_returnedError);
        goto error;
    }

    session = [[AVCaptureSession alloc] init];
    
    
    if( ![session canAddInput:input] )
    {
        NSLog(@"default video capture device could not be added to capture session");
        goto error;
    }
    [session addInput:input];

    captureOutput = [[AVCaptureVideoDataOutput alloc] init];
    [captureOutput setVideoSettings:[NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithInt:h], kCVPixelBufferHeightKey,
                                     [NSNumber numberWithInt:w], kCVPixelBufferWidthKey,
                                     [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],
                                     (id)kCVPixelBufferPixelFormatTypeKey, nil]];


    if( ![session canAddOutput:captureOutput] )
    {
        NSLog(@"output could not be added to capture session");
        goto error;
    }
    [session addOutput:captureOutput];
    
    [session startRunning]; // start the capture session
    NSLog(@"Video device ready!");
    
    dispatch_queue = dispatch_queue_create("jmx.videocapture", NULL);

    
    [captureOutput setSampleBufferDelegate:controller queue:dispatch_queue];
    return;
error:
    //[= exitQTKitOnThread];
    [input release];
    
}

- (void)setPixelBufferAttributes:(NSDictionary *)attributes
{
    if (captureOutput) {
        [captureOutput setVideoSettings:attributes];
    }
}

- (void)stopCapture
{
    if (session) {
        [session stopRunning];
        [session removeOutput:captureOutput];
        if (input) {
            [session removeInput:input];
            [session release];
            [input release];
            dispatch_release(dispatch_queue);
            input = nil;
        }
        session = nil;
    }
    if (captureOutput) {
        [captureOutput release];
        captureOutput = NULL;
    }
    if (device) {
        // NOTE: this is autoreleased because we are not retaining it (but the session is)
        /*
        if ([device isOpen])
            [device close];
        [device release];
         */
        device = nil;
    }
    
}

- (NSSize)size
{
    return NSMakeSize(width, height);
}

@end

@implementation JMXQtVideoCaptureEntity : JMXVideoCapture

- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    if (currentFrame)
        [currentFrame release];
    CVImageBufferRef videoFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    currentFrame = [[CIImage imageWithCVImageBuffer:videoFrame] retain];
    [self tick:CVGetCurrentHostTime()];
}

- (id)init
{
    self = [super init];
    if (self) {
        grabber = [[JMXQtVideoGrabber alloc] init];
        self.label = @"JMXQtVideoCapture";
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

- (void)start
{
	[grabber startCapture:self];
    [super start];
}

- (void)stop
{
	[grabber stopCapture];
    [super stop];
}

- (void)setSize:(JMXSize *)newSize
{
    [super setSize:newSize];
    @synchronized(self) {
        [grabber setPixelBufferAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:newSize.height], kCVPixelBufferHeightKey,
                                          [NSNumber numberWithInt:newSize.width], kCVPixelBufferWidthKey,
                                          [NSNumber numberWithInt:kCVPixelFormatType_32ARGB],
                                          (id)kCVPixelBufferPixelFormatTypeKey, nil]];
    }
}


@end
