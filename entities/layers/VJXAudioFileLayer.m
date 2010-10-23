//
//  VJXAudioFileLayer.m
//  VeeJay
//
//  Created by xant on 9/26/10.
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

#import "VJXAudioFileLayer.h"
#import "VJXAudioFile.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXAudioFileLayer

@synthesize repeat;

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"mp3", @"mp2", @"aif", @"aiff", @"wav", @"avi", nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        audioFile = nil;
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        repeat = YES;
        [self registerInputPin:@"repeat" withType:kVJXNumberPin andSelector:@"doRepeat:"];
        currentSample = nil;
    }
    return self;
}

- (void)dealloc
{
    if (currentSample)
        [currentSample release];
    if (audioFile)
        [audioFile release];
    [super dealloc];
}

- (BOOL)open:(NSString *)file
{
    if (file) {
        @synchronized(audioFile) {
            audioFile = [[VJXAudioFile audioFileWithURL:[NSURL fileURLWithPath:file]] retain];
            if (audioFile) {
                self.frequency = [NSNumber numberWithDouble:([audioFile sampleRate]/512.0)];
                NSArray *path = [file componentsSeparatedByString:@"/"];
                self.name = [path lastObject];
                return YES;
            }
        }
    }
    return NO;
}

- (void)close
{
    // TODO - IMPLEMENT
}

- (void)tick:(uint64_t)timeStamp
{
    VJXAudioBuffer *sample = nil;
    if (active && audioFile) {
        sample = [audioFile readFrames:512];
        if ([audioFile currentOffset] >= [audioFile numFrames] - (512*[audioFile numChannels])) {
            [audioFile seekToOffset:0];
            if (repeat) { // loop on the file if we have to
                sample = [audioFile readFrames:512];
            } else {
                active = FALSE;
            }
        }
    } 
    if (sample)
        [outputPin deliverData:sample fromSender:self];
    else
        [outputPin deliverData:nil fromSender:self];
    [self outputDefaultSignals:timeStamp];
}

- (void)doRepeat:(id)value
{
    repeat = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
    ? YES
    : NO;
}

@end
