//
//  JMXAudioSpectrumAnalyzer.m
//  JMX
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import <Quartz/Quartz.h>
#import "JMXSpectrumAnalyzer.h"
#import "JMXAudioBuffer.h"
#import "JMXAudioFormat.h"
#import "JMXDrawPath.h"
#include "JMXAudioSpectrumAnalyzer.h"
#include "JMXScript.h"
#import "NSColor+V8.h"

JMXV8_EXPORT_NODE_CLASS(JMXAudioSpectrumAnalyzer);

// XXX - just a test
#undef memcpy
#define memcpy(__dst, __src, __size) bcopy(__src, __dst, __size)

#define kJMXAudioSpectrumImageWidth 320
#define kJMXAudioSpectrumImageHeight 240

static int _defaultFrequencies[kJMXAudioSpectrumNumFrequencies] = 
    { 30, 80, 125, 250, 350, 500, 750, 1000, 2000, 3000, 4000, 5000, 8000, 16000 }; 

@implementation JMXAudioSpectrumAnalyzer

- (id)init
{
    NSMutableArray *freqs = [NSMutableArray arrayWithCapacity:kJMXAudioSpectrumNumFrequencies];
    for (int i = 0; i < kJMXAudioSpectrumNumFrequencies; i++) {
        [freqs addObject:[NSNumber numberWithInt:_defaultFrequencies[i]]];
    }
    return [self initWithFrequencies:freqs];
}

- (id)initWithFrequencies:(NSArray *)freqs
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kJMXAudioPin andSelector:@"newSample:"];
        // Set the client format to 32bit float data
        // Maintain the channel count and sample rate of the original source format
        UInt32 sampleSize = sizeof(Float32);
        audioFormat.mSampleRate = 44100; // HC
        audioFormat.mChannelsPerFrame = 2; // HC
        audioFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        audioFormat.mFormatID = kAudioFormatLinearPCM;
        audioFormat.mBytesPerPacket = sampleSize * audioFormat.mChannelsPerFrame;
        audioFormat.mFramesPerPacket = 1;
        audioFormat.mBytesPerFrame = sampleSize * audioFormat.mChannelsPerFrame;
        audioFormat.mBitsPerChannel = 8*sampleSize;
        blockSize = 1024; // double the num of bins
        numBins = blockSize>>1;
        converter = nil;
        
        // setup the buffer where the squared magnitude will be put into
        spectrumBuffer = (AudioBufferList *)calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
        spectrumBuffer->mNumberBuffers = 2;
        spectrumBuffer->mBuffers[0].mNumberChannels = 1;
        spectrumBuffer->mBuffers[0].mData = calloc(1, sampleSize * numBins);
        spectrumBuffer->mBuffers[0].mDataByteSize = sampleSize * numBins;
        spectrumBuffer->mBuffers[1].mNumberChannels = 1;
        spectrumBuffer->mBuffers[1].mData = calloc(1, sampleSize * numBins);
        spectrumBuffer->mBuffers[1].mDataByteSize = sampleSize * numBins;
        minAmp = (Float32*) calloc(2, sizeof(Float32));
        maxAmp = (Float32*) calloc(2, sizeof(Float32));
        
        analyzer = [[JMXSpectrumAnalyzer alloc] initWithSize:blockSize hopSize:numBins channels:2 maxFrames:512];

        // buffer to store a deinterleaved version of the received sample
        deinterleavedBuffer = (AudioBufferList *)calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
        deinterleavedBuffer->mNumberBuffers = 2;
        deinterleavedBuffer->mBuffers[0].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[0].mDataByteSize = sampleSize*numBins;
        deinterleavedBuffer->mBuffers[0].mData = calloc(1,sampleSize*numBins);
        deinterleavedBuffer->mBuffers[1].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[1].mDataByteSize = sampleSize*numBins;
        deinterleavedBuffer->mBuffers[1].mData = calloc(1,sampleSize*numBins);
        
        frequencies = [freqs copy];
        // setup the frequency pins
        frequencyPins = [[NSMutableArray alloc] init];
        for (NSNumber *frequency in frequencies) {
            int freq = [frequency intValue];
            NSString *pinName = freq < 1000
                              ? [NSString stringWithFormat:@"f%dHz", freq]
                              : [NSString stringWithFormat:@"f%dKhz", freq/1000]; 
            [frequencyPins addObject:[self registerOutputPin:pinName withType:kJMXNumberPin]];
        }
        
        imagePin = [self registerOutputPin:@"image" withType:kJMXImagePin];
        imageSizePin = [self registerOutputPin:@"imageSize" withType:kJMXSizePin];
        [imageSizePin setContinuous:NO];
        NSSize frameSize = { kJMXAudioSpectrumImageWidth, kJMXAudioSpectrumImageHeight };
        [imageSizePin deliverData:[JMXSize sizeWithNSSize:frameSize]];
        drawer = [[JMXDrawPath drawPathWithFrameSize:
                               [JMXSize sizeWithNSSize:NSMakeSize(kJMXAudioSpectrumImageWidth, kJMXAudioSpectrumImageHeight)]] retain];
        drawer.invertYCoordinates = YES;
    }
    return self;
}

- (void)dealloc
{
    free(spectrumBuffer->mBuffers[0].mData);
    free(spectrumBuffer->mBuffers[1].mData);
    free(spectrumBuffer);
    free(deinterleavedBuffer->mBuffers[0].mData);
    free(deinterleavedBuffer->mBuffers[1].mData);
    free(deinterleavedBuffer);
    free(minAmp);
    free(maxAmp);
    if (drawer)
        [drawer release];
    [super dealloc];
}

// TODO - optimize
- (void)drawSpectrumImage
{    
    [drawer clear];

    for (int i = 0; i < kJMXAudioSpectrumNumFrequencies; i++) {
        Float32 value = frequencyValues[i];
        int barWidth = kJMXAudioSpectrumImageWidth/kJMXAudioSpectrumNumFrequencies;
        NSRect frequencyRect;
        frequencyRect.origin.x = i*barWidth+2;
        frequencyRect.origin.y = 20;
        frequencyRect.size.width = barWidth-4;
        UInt32 topPadding = frequencyRect.origin.y + 20; // HC
        frequencyRect.size.height = MIN(value*0.75, kJMXAudioSpectrumImageHeight-topPadding);
        drawer.strokeStyle = [NSColor yellowColor];
        drawer.fillStyle = [NSColor yellowColor];
        [drawer fillRect:[JMXPoint pointWithNSPoint:frequencyRect.origin]
                    size:[JMXSize sizeWithNSSize:frequencyRect.size]];
        [drawer stroke];
        [drawer fill];
        int freq = [[frequencies objectAtIndex:i] intValue];
        // XXX - how to use bordercolor now? 
        NSString *freqLabel = freq < 1000
                            ? [NSString stringWithFormat:@"%d", freq]
                            : [NSString stringWithFormat:@"%dK", freq/1000]; 

        NSPoint nsPoint;
        nsPoint.x = frequencyRect.origin.x;
        nsPoint.y = 4;
        JMXPoint *point = [JMXPoint pointWithNSPoint:nsPoint];
        drawer.font = [NSFont labelFontOfSize:10];
        drawer.strokeStyle = [NSColor lightGrayColor];
        [drawer strokeText:freqLabel atPoint:point];
        [drawer stroke];
        [drawer fill];
    }
    [imagePin deliverData:[drawer currentFrame]];
}

- (void)newSample:(JMXAudioBuffer *)sample
{
    if (!sample)
        return;
    // XXX - get rid of this stupid lock
    @synchronized(analyzer) {
        AudioBufferList *bufferList = sample.bufferList;
        switch(bufferList->mNumberBuffers) {
        case 1:
            switch (bufferList->mBuffers[0].mNumberChannels) {
            case 1: // we got a mono sample, let's just copy that across all channels
                for (int i = 0; i < deinterleavedBuffer->mNumberBuffers; i++) {
                    UInt32 sizeToCopy = MIN(bufferList->mBuffers[0].mDataByteSize, 
                                            deinterleavedBuffer->mBuffers[i].mDataByteSize);
                    memcpy(deinterleavedBuffer->mBuffers[i].mData, bufferList->mBuffers[0].mData, sizeToCopy);
                }
                break;
            case 2:
                {
                    UInt32 numFrames = (UInt32)[sample numFrames];
                    for (int j = 0; j < numFrames; j++) {
                        uint8_t *frame = ((uint8_t *)bufferList->mBuffers[0].mData) + (j*8);
                        memcpy((u_char *)deinterleavedBuffer->mBuffers[0].mData+(j*4), frame, 4);
                        memcpy((u_char *)deinterleavedBuffer->mBuffers[1].mData+(j*4), frame + 4, 4);
                    }
                }
                break;
            default: // more than 2 channels are not supported yet
                // TODO - error messages
                return;
            }
            break;
        case 2: // same number of channels (2 at the moment)
            for (int i = 0; i < deinterleavedBuffer->mNumberBuffers; i++) {
                UInt32 sizeToCopy = MIN(bufferList->mBuffers[i].mDataByteSize, 
                                        deinterleavedBuffer->mBuffers[i].mDataByteSize);
                memcpy(deinterleavedBuffer->mBuffers[i].mData, bufferList->mBuffers[i].mData, sizeToCopy);
            }
            break;
        default: // buffers with more than 2 channels are not supported yet
            // TODO - error messages
            return;
        }
        [analyzer processForwards:(UInt32)[sample numFrames] input:deinterleavedBuffer];

        [analyzer getMagnitude:spectrumBuffer min:minAmp max:maxAmp];
        
        for (UInt32 i = 0; i < kJMXAudioSpectrumNumFrequencies; i++) {	// for each frequency
            int freq = [[frequencies objectAtIndex:i] intValue];
            int offset = freq*numBins/44100*analyzer.numChannels;
            Float32 freqValue = (((Float32 *)(spectrumBuffer->mBuffers[0].mData))[offset] +
                                ((Float32 *)(spectrumBuffer->mBuffers[1].mData))[offset]) * 0.5;
            if (freqValue < 0.0)
                freqValue = 0.0;
            
            NSNumber *numberValue = [NSNumber numberWithFloat:freqValue];
            [(JMXOutputPin *)[frequencyPins objectAtIndex:i] deliverData:numberValue];
            frequencyValues[i] = freqValue;
        }
        if (runcycleCount%5 == 0 && imagePin.connected) { // draw the image only once every 10 samples
            [self drawSpectrumImage];
        }
        runcycleCount++;
    }
}

// override outputPins to return them properly sorted
- (NSArray *)outputPins
{
    NSMutableArray *pins = [[NSMutableArray alloc] initWithArray:frequencyPins copyItems:NO];
    [pins addObject:activeOut];
    [pins addObject:imagePin];
    [pins addObject:imageSizePin];
    return [pins autorelease];
}

- (int)numberOfFrequencies
{
    return (int)[frequencies count];
}

- (int)frequencyAtIndex:(NSUInteger)index
{
    if ([frequencies count] > index)
        return [[frequencies objectAtIndex:index] intValue];
    return -1;
}

#pragma mark V8
using namespace v8;

static v8::Handle<Value>frequencies(const Arguments& args)
{
    HandleScope handleScope;
    JMXAudioSpectrumAnalyzer *entity = (JMXAudioSpectrumAnalyzer *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Array> list = v8::Array::New(entity.numberOfFrequencies);
    for (int i = 0; i < entity.numberOfFrequencies; i++) {
        int freq = [entity frequencyAtIndex:i];
        list->Set(i, v8::Integer::New(freq));
    }
    return handleScope.Close(list);
}

static v8::Handle<Value> frequency(const Arguments& args)
{
    HandleScope handleScope;
    JMXAudioSpectrumAnalyzer *entity = (JMXAudioSpectrumAnalyzer *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    int freq = (int)args[0]->IntegerValue();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *label = freq < 1000
                    ? [NSString stringWithFormat:@"%d", freq]
                    : [NSString stringWithFormat:@"%dK", freq/1000];
    JMXPin *pin = [entity outputPinWithLabel:label];
    if (pin) {
        NSNumber *value = [pin readData];
        if (value) {
            [pool drain];
            return Number::New([value doubleValue]);
        }
    }
    [pool drain];
    return v8::Undefined();
}


+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("AudioSpectrum"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    objectTemplate->PrototypeTemplate()->Set("frequencies", FunctionTemplate::New(frequencies));
    objectTemplate->PrototypeTemplate()->Set("frequency", FunctionTemplate::New(frequency));
    return objectTemplate;
}

@end
