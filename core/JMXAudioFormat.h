//
//  JMXAudioFormat.h
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
/*!
 @header JMXAudioFormat.h
 @abstract encapsulates an AudioStreamBasicDescription structure (CoreAudio)
           providing an obj-c API
 */
#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudioTypes.h>

/*!
 @class JMXAudioFormat
 @abstract class to encapsulate an AudioStreamBasicDescription structure (CoreAudio) providing an obj-c API
 */
@interface JMXAudioFormat : NSObject {
@private
    AudioStreamBasicDescription audioStreamBasicDescription;
}

/*!
 @property audioStreamBasicDescription
 */
@property (readonly)AudioStreamBasicDescription audioStreamBasicDescription;
/*!
 @property sampleRate
 */
@property (readwrite) Float64 sampleRate;
/*!
 @property formatID
 */
@property (readwrite) UInt32  formatID;
/*!
 @property formatFlags
 */
@property (readwrite) UInt32  formatFlags;
/*!
 @property bytesPerPacket
 */
@property (readwrite) UInt32  bytesPerPacket;
/*!
 @property framesPerPacket
 */
@property (readwrite) UInt32  framesPerPacket;
/*!
 @property bytesPerFrame
 */
@property (readwrite) UInt32  bytesPerFrame;
/*!
 @property channelsPerFrame
 */
@property (readwrite) UInt32  channelsPerFrame;
/*!
 @property bitsPerChannel
 */
@property (readwrite) UInt32  bitsPerChannel;
/*!
 @property isInterleaved
 */
@property (readwrite) BOOL  isInterleaved;


+ (id)formatWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription;
- (id)initWithAudioStreamDescription:(AudioStreamBasicDescription)formatDescription;

@end
