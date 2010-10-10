//
//  VJXAudioSpectrumAnalyzer.h
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"
#import <AudioToolbox/AudioConverter.h>

@class VJXAudioAnalyzer;

@interface VJXAudioSpectrumAnalyzer : VJXEntity {
@private
    VJXPin *audioInputPin;
    AudioStreamBasicDescription audioFormat;
    VJXAudioAnalyzer *analyzer;
    AudioConverterRef converter;
    AudioBufferList *spectrumBuffer;
    Float32 *minAmp;
    Float32 *maxAmp;
    AudioBufferList *deinterleavedBuffer;
    UInt32 blockSize;
    UInt32 numBins;
}

@end
