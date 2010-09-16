//
//  VJXAudioFile.h
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "VJXAudioBuffer.h"

@interface VJXAudioFile : NSObject {
@private
    ExtAudioFileRef audioFile;
    AudioStreamBasicDescription fileFormat;
}

+ (id)audioFileWithURL:(NSURL *)url;

- (VJXAudioBuffer *)readFrame;
- (VJXAudioBuffer *)readFrames:(NSUInteger)numFrames;

- (BOOL)seekToOffset:(NSInteger)offset;
- (NSUInteger)sampleRate;
- (NSUInteger)numChannels;
- (NSInteger)currentOffset;
- (NSUInteger)bitsPerChannel;

@end
