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
#import <QTKit/QTKit.h>
#import <Cocoa/Cocoa.h>
#define __JMXV8__
#import "JMXQtVideoCaptureEntity.h"
#include "JMXScript.h"

#define JMX_GRABBER_WIDTH_MAX 640
#define JMX_GRABBER_HEIGHT_MAX 480

/*
 * QTKit Bridge
 */

JMXV8_EXPORT_ENTITY_CLASS(JMXQtVideoCaptureEntity);

@interface JMXQtVideoGrabber : QTCaptureDecompressedVideoOutput
{
    QTCaptureDeviceInput         *input;
    QTCaptureMovieFileOutput     *captureOutput;
    QTCaptureSession             *session;
    QTCaptureDevice              *device;
    int                          width;
    int                          height;
}

- (id)init;
- (void)startCapture:(JMXQtVideoCaptureEntity *)controller;
- (void)stopCapture;
- (NSSize)size;
@end

@implementation JMXQtVideoGrabber : QTCaptureDecompressedVideoOutput

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
        [session removeOutput:self];
       // if (input) {
        [session removeInput:input];
        [session release];
        [input release];
        input = nil;
        //}
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
        device = nil;
    }
    
}

- (NSSize)size
{
    return NSMakeSize(width, height);
}

@end


@implementation JMXQtVideoCaptureEntity : JMXVideoCapture

- (void)captureOutput:(QTCaptureOutput *)captureOutput 
  didOutputVideoFrame:(CVImageBufferRef)videoFrame 
     withSampleBuffer:(QTSampleBuffer *)sampleBuffer 
       fromConnection:(QTCaptureConnection *)connection
{
    if (currentFrame)
        [currentFrame release];
    currentFrame = [[CIImage imageWithCVImageBuffer:videoFrame] retain];
    [self tick:CVGetCurrentHostTime()];
}

- (id)init
{
    self = [super init];
    if (self) {
        grabber = [[JMXQtVideoGrabber alloc] init];
        self.name = @"JMXQtVideoCapture";
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
