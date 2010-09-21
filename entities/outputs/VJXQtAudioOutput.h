//
//  VJXQtAudioOutput.h
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "VJXAudioOutput.h"

@class VJXAudioReceiver;

@interface VJXQtAudioOutput : VJXAudioOutput {
    VJXAudioReceiver *audioInput;
    QTCaptureAudioPreviewOutput *audioOutput;
    QTCaptureSession *session;
    NSArray *audioDevices;
}

@end
