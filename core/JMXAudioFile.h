//
//  JMXAudioFile.h
//  JMX
//
//  Created by xant on 9/15/10.
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
/*!
 @header JMXAudioFile.h
 @discussion Allow to access samples from an audiofile.
             This class wraps AudioToolBox functionalities
             providing an obj-c API
 */

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/ExtendedAudioFile.h>
#import "JMXAudioBuffer.h"

#define kJMXAudioFileBufferCount 4096

/*!
 @class JMXAudioFile
 @discussion This class allow to access samples from audio files.
             Note that all samples will be returned as :
             44100 float32 stereo interleaved
 */
@interface JMXAudioFile : NSObject {
@private
    ExtAudioFileRef audioFile;
    AudioStreamBasicDescription fileFormat;
    JMXAudioBuffer *samples[kJMXAudioFileBufferCount];
    UInt32 rOffset;
    UInt32 wOffset;
    BOOL isFilling;
}

/*!
 @property sampleRate
 */
@property (readonly) NSUInteger sampleRate;
/*!
 @property numChannels
 */
@property (readonly) NSUInteger numChannels;
/*!
 @property currentOffset
 */
@property (readonly) NSInteger currentOffset;
/*!
 @property bitsPerChannel
 */
@property (readonly) NSUInteger bitsPerChannel;
/*!
 @property numFrames
 */
@property (readonly) NSInteger numFrames;

/*!
 @method audioFileWithURL
 @abstract create a new (autoreleased) JMXAudioFile opening the specified url
 */
+ (id)audioFileWithURL:(NSURL *)url;

- (id)initWithURL:(NSURL *)url;

/*!
 @method readSample
 @abstract read next audio frame
 */
- (JMXAudioBuffer *)readSample;
/*!
 @method readFrames:
 @abstract read the specified number of frames from the audio file
 @param numFrames the number of frames to read
 */
- (JMXAudioBuffer *)readFrames:(NSUInteger)numFrames;
/*!
 @method seekToOffset:
 @abstract seek to the specified offset
 @param offset The offset to use at next read operation
 */
- (BOOL)seekToOffset:(NSInteger)offset;

/* TODO - these should become properties */

@end
