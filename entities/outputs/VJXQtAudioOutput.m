//
//  VJXQtAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXQtAudioOutput.h"

@interface VJXAudioConnection : QTCaptureConnection
{
    id owner;
}
- (id)initWithOwner:(id)theOwner;
@property (readonly) id owner;
@end

@implementation VJXAudioConnection
@synthesize owner;
- (id)initWithOwner:(id)theOwner
{
    if (self = [super init])
        owner = theOwner;
    return self;
}

- (BOOL)isEnabled
{
    return YES;
}

- (QTFormatDescription *)formatDescription
{
    return nil;
}

- (NSString *)mediaType
{
    return QTMediaTypeSound;
}
@end

@interface VJXAudioReceiver : QTCaptureInput
{
    QTCaptureConnection *connection;
}
@end

@implementation VJXAudioReceiver

- (id)init
{
    if (self = [super init]) {
        connection = [[VJXAudioConnection alloc] initWithOwner:self];
    }
    return self;
}

- (NSArray *)connections
{
    return [NSArray arrayWithObject:connection];
}

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
        
        audioInput = [[VJXAudioReceiver alloc] init];
        if (![session addInput:audioInput error:&error]) {
            
            // TODO - Error Messages
        }
        // Start the session
        [session startRunning];
    }
    return self;
}


@end
