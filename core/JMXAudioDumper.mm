//
//  JMXAudioMixer.m
//  JMX
//
//  Created by xant on 9/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXAudioDumper.h"
#include <Accelerate/Accelerate.h>
#import "JMXAudioFormat.h"
#import "JMXAudioDevice.h"
#import <QuartzCore/QuartzCore.h>
#import "JMXThreadedEntity.h"
#import <AudioToolbox/AudioConverter.h>

@implementation JMXAudioDumper
{
    FILE *outFile;
    int   dumpCounter;
}

- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kJMXAudioPin andSelector:@"audio:"];
        outFile = fopen("/tmp/jmx-audiodumper.dump", "w");

        return self;
    }
    return nil;
}

- (void)dealloc
{
    if (outFile)
        fclose(outFile);
    [super dealloc];
}

- (void)audio:(JMXAudioBuffer *)buffer
{
    AudioStreamBasicDescription inputDescription = buffer.format.audioStreamBasicDescription;

    if (inputDescription.mFormatID != kAudioFormatLinearPCM)
        return;

    if (inputDescription.mFramesPerPacket != 1)
        return;

    const int BufferCount = 100;
    
    if (dumpCounter++ < BufferCount)
        fwrite(buffer.data.bytes, 1, buffer.data.length, outFile);

    if (dumpCounter++ == BufferCount) {
        fclose(outFile);
        outFile = nil;
    }
}

@end
