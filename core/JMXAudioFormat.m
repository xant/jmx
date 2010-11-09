//
//  JMXAudioFormat.m
//  JMX
//
//  Created by xant on 9/25/10.
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

#import "JMXAudioFormat.h"


@implementation JMXAudioFormat

@synthesize audioStreamBasicDescription;

+ (id)formatWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription
{
    JMXAudioFormat *obj = [JMXAudioFormat alloc];
    if (obj)
        return [[obj initWithAudioStreamDescription:formatDescription] autorelease];
    return nil;
}

- (id)initWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription
{
    self = [super init];
    if (self) {
        memcpy(&audioStreamBasicDescription, &formatDescription, sizeof(audioStreamBasicDescription));
    }
    return self;
}

- (AudioStreamBasicDescription)audioStreamBasicDescription
{
    return audioStreamBasicDescription;
}

- (Float64)sampleRate
{
    return audioStreamBasicDescription.mSampleRate;
}

- (void)setSampleRate:(Float64)theSampleRate
{
    audioStreamBasicDescription.mSampleRate = theSampleRate;
}

- (UInt32)formatID
{
    return audioStreamBasicDescription.mFormatID;
}

- (void)setFormatID:(UInt32)theFormatID
{
    audioStreamBasicDescription.mFormatID = theFormatID;
}

- (UInt32)formatFlags
{
    return audioStreamBasicDescription.mFormatFlags;
}

- (void)setFormatFlags:(UInt32)theFormatFlags
{
    audioStreamBasicDescription.mFormatFlags = theFormatFlags;
}

- (UInt32)framesPerPacket
{
    return audioStreamBasicDescription.mFramesPerPacket;
}

- (void)setFramesPerPacket:(UInt32)theFramesPerPacket
{
    audioStreamBasicDescription.mFramesPerPacket = theFramesPerPacket;
}

- (UInt32)bytesPerPacket
{
    return audioStreamBasicDescription.mBytesPerPacket;
}

- (void)setBytesPerPacket:(UInt32)theBytesPerPacket
{
    audioStreamBasicDescription.mBytesPerPacket = theBytesPerPacket;
}

- (UInt32)channelsPerFrame
{
    return audioStreamBasicDescription.mChannelsPerFrame;
}

- (void)setChannelsPerFrame:(UInt32)theChannelsPerFrame
{
    audioStreamBasicDescription.mChannelsPerFrame = theChannelsPerFrame;
}

- (UInt32)bytesPerFrame
{
	return audioStreamBasicDescription.mBytesPerFrame;
}

- (void)setBytesPerFrame:(UInt32)theBytesPerFrame
{
	audioStreamBasicDescription.mBytesPerFrame = theBytesPerFrame;
}

- (UInt32)bitsPerChannel
{
    return audioStreamBasicDescription.mBitsPerChannel;
}

- (void)setBitsPerChannel:(UInt32)theBitsPerChannel
{
    audioStreamBasicDescription.mBitsPerChannel = theBitsPerChannel;
}

- (Boolean)                        isInterleaved
{
	return ( 0 == ( audioStreamBasicDescription.mFormatFlags & kLinearPCMFormatFlagIsNonInterleaved ));
}

- (Boolean) isLinearPCMFormat
{
	return ( kAudioFormatLinearPCM == audioStreamBasicDescription.mFormatID );
}

- (Boolean) isCanonicalFormat
{
	return (
            ( [self isLinearPCMFormat] )
            && (( kAudioFormatFlagsNativeFloatPacked | kLinearPCMFormatFlagIsNonInterleaved ) == ( audioStreamBasicDescription.mFormatFlags | kLinearPCMFormatFlagIsNonInterleaved ))
            && (( sizeof(Float32) * 8 ) == audioStreamBasicDescription.mBitsPerChannel )
            && ( 1 == audioStreamBasicDescription.mFramesPerPacket )
            );
}

- (Boolean) isNativeFormat
{
	return ( [self isCanonicalFormat] && [self isInterleaved] );
}

- (void) _normalizeBytesForChannels
{
	unsigned bytesPerFrame;
    
	if ( [self isInterleaved] )
	{
		bytesPerFrame = sizeof(Float32) * audioStreamBasicDescription.mChannelsPerFrame;
	}
	else
	{
		bytesPerFrame = sizeof(Float32);
	}
	audioStreamBasicDescription.mBytesPerFrame = audioStreamBasicDescription.mBytesPerPacket = bytesPerFrame;
}

- (void)setIsInterleaved:(Boolean)interleave
{
	if ( [self isLinearPCMFormat] )
	{
		if ( interleave )
		{
			audioStreamBasicDescription.mFormatFlags &= ~kLinearPCMFormatFlagIsNonInterleaved;
		}
		else
		{
			audioStreamBasicDescription.mFormatFlags |= kLinearPCMFormatFlagIsNonInterleaved;
		}
		if ( [self isCanonicalFormat] )
		{
			[self _normalizeBytesForChannels];
		}
	}
}

@end
