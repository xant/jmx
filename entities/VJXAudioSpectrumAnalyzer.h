//
//  VJXAudioSpectrumAnalyzer.h
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioConverter.h>
#import "VJXEntity.h"

#define kVJXAudioSpectrumNumFrequencies 14
#define kVJXAudioSpectrumImageBufferCount 2

@class VJXSpectrumAnalyzer;

@interface VJXAudioSpectrumAnalyzer : VJXEntity {
@private
    VJXInputPin *audioInputPin;
    VJXOutputPin *imagePin;
    VJXOutputPin *imageSizePin;
    AudioStreamBasicDescription audioFormat;
    VJXSpectrumAnalyzer *analyzer;
    AudioConverterRef converter;
    AudioBufferList *spectrumBuffer;
    Float32 *minAmp;
    Float32 *maxAmp;
    UInt32 blockSize;
    UInt32 numBins;
    NSMutableArray *frequencyPins;
    NSGraphicsContext *imageContext;
    CGLayerRef pathLayers[kVJXAudioSpectrumImageBufferCount];
    UInt32 pathLayerOffset;
    CIImage *currentImage;
    AudioBufferList *deinterleavedBuffer;
    UInt32 runcycleCount;
    Float32 frequencyValues[kVJXAudioSpectrumNumFrequencies];
}

@end

#ifdef __VJXV8__
VJXV8_DECLARE_ENTITY_CONSTRUCTOR(VJXAudioSpectrumAnalyzer);
#endif