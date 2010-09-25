//
//  VJXAudioBuffer.h
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@interface VJXAudioBuffer : NSObject {
@private
    AudioBuffer buffer;
    AudioStreamBasicDescription format;
}

+ (id)audioBufferWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;
- (id)initWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;
- (NSUInteger)numChannels;
- (NSData *)data;
- (NSUInteger)numFrames;
- (NSUInteger)bytesPerFrame;
- (NSUInteger)bitsPerChannel;
- (NSUInteger)channelsPerFrame;
- (NSUInteger)sampleRate;
- (NSUInteger)numChannels;
- (OSStatus) fillComplexBuffer:(AudioBufferList *)ioData countPointer:(UInt32 *)ioNumberFrames waitForData:(Boolean)wait offset:(UInt32)offset;
@end
