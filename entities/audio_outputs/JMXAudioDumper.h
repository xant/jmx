//
//  JMXAudioDumper.h
//  JMX
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"

#define kJMXAudioMixerSamplesBufferCount 512

@class JMXPin;
@class JMXAudioBuffer;
@class JMXAudioDevice;

@interface JMXAudioDumper : JMXEntity {
@protected
    NSArray *audioInputs;
    JMXInputPin *audioInputPin;
@private
}

@end


