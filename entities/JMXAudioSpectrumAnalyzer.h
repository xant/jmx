//
//  JMXAudioSpectrumAnalyzer.h
//  JMX
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AudioToolbox/AudioConverter.h>
#import "JMXEntity.h"

#define kJMXAudioSpectrumNumFrequencies 14
#define kJMXAudioSpectrumImageBufferCount 32

@class JMXSpectrumAnalyzer;
@class JMXDrawPath;

@interface JMXAudioSpectrumAnalyzer : JMXEntity {
@private
    JMXInputPin *audioInputPin;
    JMXOutputPin *imagePin;
    JMXOutputPin *imageSizePin;
    AudioStreamBasicDescription audioFormat;
    JMXSpectrumAnalyzer *analyzer;
    AudioConverterRef converter;
    AudioBufferList *spectrumBuffer;
    Float32 *minAmp;
    Float32 *maxAmp;
    UInt32 blockSize;
    UInt32 numBins;
    NSMutableArray *frequencyPins;
    JMXDrawPath *drawer;
    AudioBufferList *deinterleavedBuffer;
    UInt32 runcycleCount;
    Float32 frequencyValues[kJMXAudioSpectrumNumFrequencies];
}

@end

#ifdef __JMXV8__
JMXV8_DECLARE_ENTITY_CONSTRUCTOR(JMXAudioSpectrumAnalyzer);
#endif
