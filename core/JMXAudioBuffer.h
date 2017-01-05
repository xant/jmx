//
//  JMXAudioBuffer.h
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
 @header JMXAudioBuffer.h
 @discussion This class provides facilities to create/use coreaudio buffers
             from obj-c code
 */
#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@class JMXAudioFormat;

/*!
 @class JMXAudioBuffer
 @abstract obj-c class to encapsulate AudioBuffer or AudioBufferList used by CoreAudio
 */
@interface JMXAudioBuffer : NSObject {
@private
    AudioBufferList *bufferList;
    JMXAudioFormat *format;
    NSMutableArray *deinterleaved;
    BOOL freeOnRelease;
}

@property (readonly) AudioBufferList *bufferList;
@property (readonly) JMXAudioFormat *format;

/*!
 @method audioBufferWithCoreAudioBuffer:andFormat:
 @abstract create a new autoreleased instance
 @param buffer The <code>AudioBuffer</code> (CoreAudio) we want to encapsulate
 @param format AudioStreamBasicDescription describing the buffer (channels, samplerate, etc)
 
 @return <code>JMXAudioBuffer</code>
 
 */
+ (id)audioBufferWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;

/*!
 @method audioBufferWithCoreAudioBufferList:buffer andFormat:format;
 @abstract create a new autoreleased instance
 @param buffer The AudioBufferList(CoreAudio) we want to encapsulate
 @param format The AudioStreamBasicDescription describing the buffers contained in the bufferlist (channels, samplerate, etc)
 
 @return <code>JMXAudioBuffer</code>
 
 */
+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format;

/*!
 @method audioBufferWithCoreAudioBufferList:andFormat:copy:freeOnRelease:
 @abstract create a new autoreleased instance
 @param buffer The AudioBufferList(CoreAudio) we want to encapsulate
 @param format The AudioStreamBasicDescription describing the buffer (channels, samplerate, etc)
 @param wantsCopy determine if we want to copy the buffer or just wrap it in a JMXAudioBuffer object
 @param wantsFree determine if the encapsulated AudioBuffer (or AudioBufferList) must be released together with the JMXAudioBuffer instance
 
 @return <code>JMXAudioBuffer</code>
 
 */
+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree;

/*!
 @method initWithCoreAudioBuffer:andFormat:
 @abstract initialize a newly created instance
 @param buffer The AudioBuffer (CoreAudio) we want to encapsulate
 @param format The AudioStreamBasicDescription describing the buffer (channels, samplerate, etc)
 
 @return <code>JMXAudioBuffer</code>
 
 */
- (id)initWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;

/*!
 @method initWithCoreAudioBufferList:andFormat:
 @abstract initialize a newly created instance
 @param buffer AudioBufferList(CoreAudio) we want to encapsulate
 @param format AudioStreamBasicDescription describing the buffers contained in the bufferlist (channels, samplerate, etc)
 
 @return <code>JMXAudioBuffer</code>
 
 */
- (id)initWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format;

/*!
 @method initWithCoreAudioBufferList:andFormat:copy:freeOnRelease:
 @abstract initialize a newly created instance
 @param audioBufferList The AudioBufferList (CoreAudio) we want to encapsulate
 @param audioFormat AudioStreamBasicDescription describing the buffer (channels, samplerate, etc)
 @param wantsCopy determine if we want to copy the buffer or just wrap it in a JMXAudioBuffer object
 @param wantsFree determine if the encapsulated AudioBuffer (or AudioBufferList) must be released together with the JMXAudioBuffer instance
 
 @return <code>JMXAudioBuffer</code>
 
 */
- (id)initWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree;

/*!
 @method numChannels
 @return the number of channels contained in the buffer
 */
- (NSUInteger)numChannels;

/*!
 @method data
 @return the raw audio buffer encapsulated in an NSData object
 */
- (NSData *)data;

/*!
 @method numFrames
 @return the number of frames contained in the buffer
 */
- (NSUInteger)numFrames;

/*!
 @method bytesPerFrame
 @return the number of bytes for each frame
 */
- (NSUInteger)bytesPerFrame;

/*!
 @method bitsPerChannel
 @return the number of bits for each channel
 */
- (NSUInteger)bitsPerChannel;

/*!
 @method channelsPerFrame
 @return the number of channels for each frame
 */
- (NSUInteger)channelsPerFrame;

/*!
 @method sampleRate
 @return the samplerate
 */
- (NSUInteger)sampleRate;


/*!
 @method fillComplexBuffer:countPointer:offset:
 @abstract fill the encapsulated buffer (or bufferlist) with the provided data
 @discussion this message can be used inside CoreAudio Procs to easily copy data across buffers
 @param ioData the source data (AudioBufferList) we want to copy 
 @param ioNumberFrames a pointer to the UInt32 where to store the number of copied frames
 @param offset the offset in the source data from where the copy must start
 
 @return noErr if the copy was successful, ioNumberFrames will be filled with
        the actual number of frames copied
 */
- (OSStatus) fillComplexBuffer:(AudioBufferList *)ioData countPointer:(UInt32 *)ioNumberFrames offset:(UInt32)offset;
@end
