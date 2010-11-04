//
//  VJXAudioOutput.h
//  VeeJay
//
//  Created by xant on 9/14/10.
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
#import <AudioToolbox/AudioConverter.h>
#import "VJXEntity.h"

@class VJXAudioBuffer;
@class VJXAudioFormat;

#define kVJXAudioOutputSamplesBufferCount 512
#define kVJXAudioOutputSamplesBufferPrefillCount 50
#define kVJXAudioOutputConvertedBufferSize 128
#define kVJXAudioOutputMaxFrames 512

@interface VJXAudioOutput : VJXEntity {
@protected
    AudioConverterRef converter;
    VJXAudioFormat *format;
    VJXOutputPin *currentSamplePin;
    VJXInputPin *audioInputPin;
    VJXAudioBuffer *currentSample;
    AudioStreamBasicDescription outputDescription;
    AudioBufferList *outputBufferList;
    void *convertedBuffer;
    UInt32 convertedOffset;
    UInt32 chunkSize;
    VJXAudioBuffer *samples[kVJXAudioOutputSamplesBufferCount];
    UInt32 wOffset;
    UInt32 rOffset;
    BOOL needsPrefill;
    NSRecursiveLock *writersLock;
}

- (VJXAudioBuffer *)currentSample;

@end
