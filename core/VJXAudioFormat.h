//
//  VJXAudioFormat.h
//  VeeJay
//
//  Created by xant on 9/25/10.
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
#import <CoreAudio/CoreAudioTypes.h>

@interface VJXAudioFormat : NSObject {
@private
    AudioStreamBasicDescription audioStreamBasicDescription;
}

@property (readonly)AudioStreamBasicDescription audioStreamBasicDescription;

+ (id)formatWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription;
- (id)initWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription;

- (Float64)sampleRate;
- (void)setSampleRate:(Float64)theSampleRate;

- (UInt32)formatID;
- (void)setFormatID:(UInt32)theFormatID;

- (UInt32)formatFlags;
- (void)setFormatFlags:(UInt32)theFormatFlags;

- (UInt32)bytesPerPacket;
- (void)setBytesPerPacket:(UInt32)theBytesPerPacket;

- (UInt32)framesPerPacket;
- (void)setFramesPerPacket:(UInt32)theFramesPerPacket;

- (UInt32)bytesPerFrame;
- (void)setBytesPerFrame:(UInt32)theBytesPerFrame;

- (UInt32)channelsPerFrame;
- (void)setChannelsPerFrame:(UInt32)theChannelsPerFrame;

- (UInt32)bitsPerChannel;
- (void)setBitsPerChannel:(UInt32)theBitsPerChannel;

- (Boolean)isInterleaved;
- (void)setIsInterleaved:(Boolean)interleave;
@end
