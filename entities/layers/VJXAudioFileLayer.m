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
#import "VJXAudioDevice.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXAudioFileLayer

@synthesize repeat, useAggregateDevice;

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"mp3", @"mp2", @"aif", @"aiff", @"wav", @"avi", nil];
}


- (void)provideSamplesToDevice:(VJXAudioDevice *)device
                     timeStamp:(AudioTimeStamp *)timeStamp
                     inputData:(AudioBufferList *)inInputData
                     inputTime:(AudioTimeStamp *)inInputTime
                    outputData:(AudioBufferList *)outOutputData
                    outputTime:(AudioTimeStamp *)inOutputTime
                    clientData:(VJXAudioFileLayer *)clientData

{
    [clientData tick:CVGetCurrentHostTime()];
}


- (id)init
{
    if (self = [super init]) {
        audioFile = nil;
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        repeat = YES;
        [self registerInputPin:@"repeat" withType:kVJXNumberPin andSelector:@"doRepeat:"];
        currentSample = nil;
        samples = nil;
        device = nil;
        useAggregateDevice = NO;
    }
    return self;
}

- (void)dealloc
{
    if (currentSample)
        [currentSample release];
    if (samples)
        [samples release];
    if (audioFile)
        [audioFile release];
    if (device)
        [device release];

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
                if (samples)
                    [samples removeAllObjects];
                else
                    samples = [[NSMutableArray alloc] init];
                // preload some frames
                for (int i = 0; i < 512; i++) { // read some frames in the ringbuffer
                    VJXAudioBuffer *sample = [audioFile readFrames:512];
                    if (sample)
                        [samples addObject:sample];
                }
                if (useAggregateDevice) {
                    if (device)
                        [device release];
                    device = [[VJXAudioDevice aggregateDevice:[[VJXAudioDevice defaultInputDevice] deviceUID] withName:self.name] retain];
                    NSLog(@"%@", [device deviceName]);
                    
                    [device setIOTarget:self 
                           withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
                         withClientData:self];
                    if (active)
                        [device deviceStart];
                }
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
                sample = [[audioFile readFrames:512] retain];
            } else {
                active = FALSE;
            }
        }
    } 
    if (sample)
        [outputPin deliverSignal:sample fromSender:self];
    else
        [outputPin deliverSignal:nil fromSender:self];
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

- (void)start
{
    if (active)
        return;
    if (useAggregateDevice) {
        active = YES;
        [device deviceStart];
    } else { // start the thread only if don't want to use the aggregate device
        [super start];
    }
}

- (void)stop
{
    if (!active)
        return;
    if (useAggregateDevice) {
        active = YES;
        [device deviceStop];
    } else { // start the thread only if don't want to use the aggregate device
        [super stop];
    }
}

- (void)setUseAggregateDevice:(BOOL)value
{
    // refulse to change the flag if we are running
    // TODO - we should just stop/restart and allow 
    //        changing the mode while running
    if (!active)
        useAggregateDevice = value;
}

@end
