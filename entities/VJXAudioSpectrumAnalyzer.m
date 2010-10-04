//
//  VJXAudioSpectrumAnalyzer.m
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioSpectrumAnalyzer.h"
#import "VJXAudioAnalyzer.h"

@implementation VJXAudioSpectrumAnalyzer

- (id)init
{
    if (self = [super init]) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:"];
        // Set the client format to 32bit float data
        // Maintain the channel count and sample rate of the original source format
        audioFormat.mSampleRate = 44100;
        audioFormat.mChannelsPerFrame = 2;
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mBytesPerPacket = 4 * audioFormat.mChannelsPerFrame;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mBytesPerFrame = 4 * audioFormat.mChannelsPerFrame;
        audioFormat.mBitsPerChannel = 32;
        UInt32 bufferSize =  4 * audioFormat.mChannelsPerFrame * 512;
        //analyzer = [[VJXAudioAnalyzer alloc] initWithSize:bufferSize hopSize: channels:2 maxFrames:512]
    }
    return self;
}

- (void)newSample:(VJXAudioBuffer *)sample
{
}

@end
