//
//  VJXAudioFileLayer.m
//  VeeJay
//
//  Created by xant on 9/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioFileLayer.h"
#import "VJXAudioFile.h"

@implementation VJXAudioFileLayer

- (id)init
{
    if (self = [super init]) {
        audioFile = nil;
        outputPin = [self registerOutputPin:@"audio" withType:kVJXAudioPin];
    }
    return self;
}

- (BOOL)open:(NSString *)file
{
    if (file) {
        @synchronized(self) {
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

- (void)tick:(uint64_t)timeStamp
{
    if (audioFile) {
        VJXAudioBuffer *sample = [audioFile readFrames:512];
        if (sample)
            [outputPin deliverSignal:sample fromSender:self];
    }
}

@end
