//
//  JMXAudioFrequency.m
//  JMX
//
//  Created by xant on 12/10/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXAudioToneGenerator.h"

@interface JMXAudioToneGenerator ()
{
    double sampleRate;
    double theta1;
    double theta2;
}
@end

@implementation JMXAudioToneGenerator
@synthesize frequency, channelSkew;

- (id)init
{
    self = [super init];
    if (self) {
        audioPin = [self registerOutputPin:@"audio" withType:kJMXAudioPin];
        audioPin.mode = kJMXPinModePassive;

        frequency = [[NSNumber numberWithDouble:300] retain];
        channelSkew = [[NSNumber numberWithDouble:7] retain];

        JMXInputPin *frequencyPin = [self registerInputPin:@"frequency" withType:kJMXNumberPin andSelector:@"setFrequency:" allowedValues:nil initialValue:frequency];
        [frequencyPin setMinLimit:[NSNumber numberWithFloat:10]];
        [frequencyPin setMaxLimit:[NSNumber numberWithFloat:500]];
        JMXInputPin *skewPin = [self registerInputPin:@"channelSkew" withType:kJMXNumberPin andSelector:@"setChannelSkew:" allowedValues:nil initialValue:channelSkew];
        [skewPin setMinLimit:[NSNumber numberWithFloat:0]];
        [skewPin setMaxLimit:[NSNumber numberWithFloat:50]];
        sampleRate = 44100;
        return self;
    }
    return nil;
}


- (void)dealloc
{
    [super dealloc];
    [frequency release];
    [channelSkew release];
}


- (JMXAudioBuffer *)audio
{
    AudioStreamBasicDescription		theOutputFormat;
    Float32 *data;
    JMXAudioBuffer *audioBuffer = nil;
    
    // Set the client format to 32bit float data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = sampleRate;
	theOutputFormat.mChannelsPerFrame = 2;
    theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 4 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 4 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 32;

    UInt32 nFrames = 512;
    UInt32 dataSize = nFrames * theOutputFormat.mBytesPerFrame;
	data = (Float32 *)malloc(dataSize);

    AudioBufferList *theDataBuffer = (AudioBufferList *)calloc(1, sizeof(AudioBufferList));
    theDataBuffer->mNumberBuffers = 1;
    theDataBuffer->mBuffers[0].mDataByteSize = dataSize;
    theDataBuffer->mBuffers[0].mNumberChannels = 2;
    theDataBuffer->mBuffers[0].mData = data;
    

    audioBuffer = [JMXAudioBuffer audioBufferWithCoreAudioBufferList:theDataBuffer
                                                      andFormat:(AudioStreamBasicDescription *)&theOutputFormat
                                                           copy:NO
                                                  freeOnRelease:YES];
    // Fixed amplitude is good enough for our purposes
	const double amplitude = 0.50;
    double freq = [frequency doubleValue];
	double theta1_increment = 2.0 * M_PI * freq / self->sampleRate;
    double theta2_increment = 2.0 * M_PI * (freq + [channelSkew doubleValue]) / self->sampleRate;

	// This is a mono tone generator so we only need the first buffer
    double channel_theta = theta1;
    double channel2_theta = theta2;

    // Generate the samples
    for (UInt32 frame = 0; frame < nFrames*2; frame+=2)
    {
        data[frame] = sin(channel_theta) * amplitude;
        data[frame+1] = sin(channel2_theta) * amplitude;
        channel_theta += theta1_increment;
        channel2_theta += theta2_increment;
        if (channel_theta > 2.0 * M_PI)
        {
            channel_theta -= 2.0 * M_PI;
        }
        if (channel2_theta > 2.0 * M_PI)
        {
            channel2_theta -= 2.0 * M_PI;
        }
    }
    theta1 = channel_theta;
    theta2 = channel2_theta;
    return audioBuffer;
    
}

@end
