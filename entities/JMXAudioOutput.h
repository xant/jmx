//
//  JMXAudioOutput.h
//  JMX
//
//  Created by xant on 9/14/10.
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
#import <AudioToolbox/AudioConverter.h>
#import "JMXEntity.h"

@class JMXAudioBuffer;
@class JMXAudioFormat;

#define kJMXAudioOutputSamplesBufferCount 512
#define kJMXAudioOutputSamplesBufferPrefillCount 50
#define kJMXAudioOutputConvertedBufferSize 128
#define kJMXAudioOutputMaxFrames 512

@interface JMXAudioOutput : JMXEntity {
@protected
    AudioConverterRef converter;
    JMXAudioFormat *format;
    JMXOutputPin *currentSamplePin;
    JMXInputPin *audioInputPin;
    JMXAudioBuffer *currentSample;
    AudioStreamBasicDescription outputDescription;
    AudioBufferList *outputBufferList;
    void *convertedBuffer;
    UInt32 convertedOffset;
    UInt32 chunkSize;
    JMXAudioBuffer *samples[kJMXAudioOutputSamplesBufferCount];
    UInt32 wOffset;
    UInt32 rOffset;
    BOOL needsPrefill;
    NSRecursiveLock *writersLock;
}

- (JMXAudioBuffer *)currentSample;

@end
