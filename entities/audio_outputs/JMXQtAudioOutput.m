//
//  JMXQtAudioOutput.m
//  JMX
//
//  Created by xant on 9/16/10.
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

#import "JMXQtAudioOutput.h"

@interface JMXAudioConnection : QTCaptureConnection
{
    id owner;
}
- (id)initWithOwner:(id)theOwner;
@property (readonly) id owner;
@end

@implementation JMXAudioConnection
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

@interface JMXAudioReceiver : QTCaptureInput
{
    QTCaptureConnection *connection;
}
@end

@implementation JMXAudioReceiver

- (id)init
{
    self = [super init];
    if (self) {
        connection = [[JMXAudioConnection alloc] initWithOwner:self];
    }
    return self;
}

- (NSArray *)connections
{
    return [NSArray arrayWithObject:connection];
}

@end

@implementation JMXQtAudioOutput
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
        
        audioInput = [[JMXAudioReceiver alloc] init];
        if (![session addInput:audioInput error:&error]) {
            
            // TODO - Error Messages
        }
        // Start the session
        [session startRunning];
    }
    return self;
}


@end
