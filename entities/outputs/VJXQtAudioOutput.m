//
//  VJXQtAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/16/10.
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
    self = [super init];
    if (self)
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
    self = [super init];
    if (self) {
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
    self = [super init];
    if (self) {
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
