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

@implementation VJXAudioFileLayer

@synthesize repeat, paused;

- (id)init
{
    if (self = [super init]) {
        audioFile = nil;
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
        repeat = YES;
        paused = NO;
        [self registerInputPin:@"repeat" withType:kVJXNumberPin andSelector:@"setRepeat:"];
        [self registerInputPin:@"paused" withType:kVJXNumberPin andSelector:@"setPaused:"];
        currentSample = nil;
        samples = nil;
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
                offset = 0;
                return YES;
            }
        }
    }
    return NO;
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(audioFile) {
        if (!paused && audioFile) {
            if ([samples count]) {
                if (currentSample)
                    [currentSample release];
                currentSample = [[samples objectAtIndex:0] retain];
                [samples removeObjectAtIndex:0];
                if (currentSample)
                    [outputPin deliverSignal:currentSample fromSender:self];
            } else {
                if ([audioFile currentOffset] >= [audioFile numFrames] - (512*[audioFile numChannels])) {
                    if (repeat) { // loop on the file if we have to
                        [audioFile seekToOffset:0];
                        currentSample = [[audioFile readFrames:512] retain];
                        if (currentSample)
                            [outputPin deliverSignal:currentSample fromSender:self];
                        offset = 0;
                    }
                }
            }
            offset++;
            while ([samples count] < 512) { // prebuffer a bunch of frames
                VJXAudioBuffer *sample = [audioFile readFrames:512];
                if (sample)
                    [samples addObject:sample];
                else
                    break;
            }
        }
    }
    [super tick:timeStamp];
}

@end
