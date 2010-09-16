//
//  VJXQtAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXQtAudioOutput.h"

@interface VJXAudioReceiver : QTCaptureDeviceInput
{
}
@end

@implementation VJXAudioReceiver
@end

@implementation VJXQtAudioOutput
- (id)init
{
    if (self = [super init]) {
        NSError *error = nil;

        // Create a capture session
        session = [[QTCaptureSession alloc] init];
        audioOutput = [[QTCaptureAudioPreviewOutput alloc] init];
        [audioOutput setVolume:1.0];
        // Attach the audio output
        [session addOutput:audioOutput error:nil];   
        
        audioDevices = [[NSArray alloc] initWithArray:[QTCaptureDevice inputDevicesWithMediaType:QTMediaTypeSound]];

        NSArray *myAudioDevices = audioDevices;
        if ([myAudioDevices count] > 0) {
            //[self setSelectedAudioDevice:[myAudioDevices objectAtIndex:0]]; // XXX - use the first audiodevice
        }   
        
        // Create a device input for the device and add it to the session
        audioDeviceInput = [[QTCaptureDeviceInput alloc] initWithDevice:[audioDevices objectAtIndex:0]];
        
        if (![session addInput:audioDeviceInput error:&error]) {
            
            // TODO - Error Messages
        }
        // Start the session
        [session startRunning];
        
         
    }
    return self;
}
@end
