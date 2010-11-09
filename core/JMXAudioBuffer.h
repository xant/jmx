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

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

@class JMXAudioFormat;

@interface JMXAudioBuffer : NSObject {
@private
    AudioBufferList *bufferList;
    JMXAudioFormat *format;
    NSMutableArray *deinterleaved;
    BOOL freeOnRelease;
}

@property (readonly) AudioBufferList *bufferList;
@property (readonly) JMXAudioFormat *format;

+ (id)audioBufferWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;
+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format;
+ (id)audioBufferWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree;
- (id)initWithCoreAudioBuffer:(AudioBuffer *)buffer andFormat:(AudioStreamBasicDescription *)format;
- (id)initWithCoreAudioBufferList:(AudioBufferList *)buffer andFormat:(AudioStreamBasicDescription *)format;
- (id)initWithCoreAudioBufferList:(AudioBufferList *)audioBufferList andFormat:(AudioStreamBasicDescription *)audioFormat copy:(BOOL)wantsCopy freeOnRelease:(BOOL)wantsFree;

- (NSUInteger)numChannels;
- (NSData *)data;
- (NSUInteger)numFrames;
- (NSUInteger)bytesPerFrame;
- (NSUInteger)bitsPerChannel;
- (NSUInteger)channelsPerFrame;
- (NSUInteger)sampleRate;
- (NSUInteger)numChannels;
- (OSStatus) fillComplexBuffer:(AudioBufferList *)ioData countPointer:(UInt32 *)ioNumberFrames waitForData:(BOOL)wait offset:(UInt32)offset;
@end
