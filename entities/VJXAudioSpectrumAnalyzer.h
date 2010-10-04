//
//  VJXAudioSpectrumAnalyzer.h
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"

@class VJXAudioAnalyzer;

@interface VJXAudioSpectrumAnalyzer : VJXEntity {
@private
    VJXPin *audioInputPin;
    AudioStreamBasicDescription audioFormat;
    VJXAudioAnalyzer *analyzer;
}

@end
