//
//  VJXAudioFile.h
//  VeeJay
//
//  Created by xant on 9/15/10.
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

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "VJXAudioBuffer.h"

#define kVJXAudioFileBufferCount 2048

@interface VJXAudioFile : NSObject {
@private
    ExtAudioFileRef audioFile;
    AudioStreamBasicDescription fileFormat;
    VJXAudioBuffer *samples[kVJXAudioFileBufferCount];
    UInt32 rOffset;
    UInt32 wOffset;
    BOOL isFilling;
}

+ (id)audioFileWithURL:(NSURL *)url;

- (VJXAudioBuffer *)readSample;
- (VJXAudioBuffer *)readFrames:(NSUInteger)numFrames;

- (BOOL)seekToOffset:(NSInteger)offset;
- (NSUInteger)sampleRate;
- (NSUInteger)numChannels;
- (NSInteger)currentOffset;
- (NSUInteger)bitsPerChannel;
- (NSInteger)numFrames;
@end
