//
//  VJXAudioSpectrumAnalyzer.m
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXSpectrumAnalyzer.h"
#import "VJXAudioBuffer.h"
#import "VJXAudioFormat.h"
#define __VJXV8__
#import "VJXAudioSpectrumAnalyzer.h"
#include "VJXJavaScript.h"

VJXV8_EXPORT_ENTITY_CLASS(VJXAudioSpectrumAnalyzer);

/*
static void decodeSpectralBuffer(DSPSplitComplex* spectra, UInt32 numSpectra, void* inUserData)
{
    VJXAudioSpectrumAnalyzer *self = (VJXAudioSpectrumAnalyzer *)inUserData;
    for (UInt32 i=0; i<numSpectra; i++) {
        UInt32 half = 512;//channel.fftSize >> 1;
		DSPSplitComplex	*freqData = &spectra[i];
        
		for (UInt32 j=0; j<half; j++){
			//NSLog(@" bin[%d]: %lf + %lfi\n", (int) j, freqData->realp[j], freqData->imagp[j]);
		}
	}
    //NSLog(@"%d", numSpectra);
}
*/

// XXX - just a test
#undef memcpy
#define memcpy(__dst, __src, __size) bcopy(__src, __dst, __size)

#define kVJXAudioSpectrumImageWidth 320
#define kVJXAudioSpectrumImageHeight 240

static int _frequencies[kVJXAudioSpectrumNumFrequencies] = { 30, 80, 125, 250, 350, 500, 750, 1000, 2000, 3000, 4000, 5000, 8000, 16000 }; 

@implementation VJXAudioSpectrumAnalyzer

- (id)init
{
    self = [super init];
    if (self) {
        audioInputPin = [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:"];
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
        
        analyzer = [[VJXSpectrumAnalyzer alloc] initWithSize:blockSize hopSize:numBins channels:2 maxFrames:512];

        // buffer to store a deinterleaved version of the received sample
        deinterleavedBuffer = (AudioBufferList *)calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
        deinterleavedBuffer->mNumberBuffers = 2;
        deinterleavedBuffer->mBuffers[0].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[0].mDataByteSize = sampleSize*512;
        deinterleavedBuffer->mBuffers[0].mData = calloc(1,sampleSize*512);
        deinterleavedBuffer->mBuffers[1].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[1].mDataByteSize = sampleSize*512;
        deinterleavedBuffer->mBuffers[1].mData = calloc(1,sampleSize*512);
        
        // setup the frequency pins
        frequencyPins = [[NSMutableArray alloc] init];
        for (int i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {
            int freq = _frequencies[i];
            NSString *pinName = freq < 1000
                              ? [NSString stringWithFormat:@"%dHz", freq]
                              : [NSString stringWithFormat:@"%dKhz", freq/1000]; 
            [frequencyPins addObject:[self registerOutputPin:pinName withType:kVJXNumberPin]];
        }
        
        currentImage = nil;
        imagePin = [self registerOutputPin:@"image" withType:kVJXImagePin];
        imageSizePin = [self registerOutputPin:@"imageSize" withType:kVJXSizePin];
        [imageSizePin setContinuous:NO];
        NSSize layerSize = { kVJXAudioSpectrumImageWidth, kVJXAudioSpectrumImageHeight };
        [imageSizePin deliverData:[VJXSize sizeWithNSSize:layerSize]];
        // initialize the storage for the spectrum images
        pathLayerOffset = 0;
        for (int i = 0; i < kVJXAudioSpectrumImageBufferCount; i++) {
            NSBitmapImageRep *imageStorage = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                                     pixelsWide:kVJXAudioSpectrumImageWidth
                                                                                     pixelsHigh:kVJXAudioSpectrumImageHeight
                                                                                  bitsPerSample:8
                                                                                samplesPerPixel:4
                                                                                       hasAlpha:YES
                                                                                       isPlanar:NO
                                                                                 colorSpaceName:NSDeviceRGBColorSpace
                                                                                    bytesPerRow:4*kVJXAudioSpectrumImageWidth
                                                                                   bitsPerPixel:4*8];
            imageContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageStorage];
            [imageStorage release];
            CGSize layerSize = { kVJXAudioSpectrumImageWidth, kVJXAudioSpectrumImageHeight };
            pathLayers[i] = (CGLayerRef)CGLayerCreateWithContext((CGContext *)[imageContext graphicsPort], layerSize , NULL );
        }
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
    if (currentImage)
        [currentImage release];
    for (int i = 0; i < kVJXAudioSpectrumImageBufferCount; i++) {
        CGLayerRelease(pathLayers[i]);
    }
    //CGLayerRelease(pathLayer);
    //[imageContext release];
    [super dealloc];
}

// TODO - optimize
- (void)drawSpectrumImage
{
    NSGraphicsContext *pathContext = nil;
    
    // initialize the coregraphics context where to draw a graphical representation
    // of the audiospectrum
    
    UInt32 pathIndex = pathLayerOffset++%kVJXAudioSpectrumImageBufferCount;
    pathContext = [NSGraphicsContext
                   graphicsContextWithGraphicsPort:CGLayerGetContext( pathLayers[pathIndex] )
                   flipped:NO];
    
    [NSGraphicsContext setCurrentContext:pathContext];
    NSRect fullFrame = { { 0, 0 }, { kVJXAudioSpectrumImageWidth, kVJXAudioSpectrumImageHeight } };
    NSBezierPath *clearPath = [NSBezierPath bezierPathWithRect:fullFrame];
    [[NSColor blackColor] setFill];
    [[NSColor blackColor] setStroke];
    [clearPath fill];
    [clearPath stroke];
    for (int i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {
        Float32 value = frequencyValues[i];
        //Draw your bezier paths here
        int barWidth = kVJXAudioSpectrumImageWidth/kVJXAudioSpectrumNumFrequencies;
        NSRect frequencyRect;
        frequencyRect.origin.x = i*barWidth+2;
        frequencyRect.origin.y = 20;
        frequencyRect.size.width = barWidth-4;
        UInt32 topPadding = frequencyRect.origin.y + 20; // HC
        frequencyRect.size.height = MIN(value*0.75, kVJXAudioSpectrumImageHeight-topPadding);
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:frequencyRect xRadius:4.0 yRadius:4.0];
        [[NSColor yellowColor] setFill];
        [[NSColor yellowColor] setStroke];
        //NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        //[transform translateXBy:0.5 yBy:0.5];
        //[path transformUsingAffineTransform:transform];
        [path fill];
        [path stroke];
        NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
        [attribs setObject:[NSFont labelFontOfSize:10] forKey:NSFontAttributeName];
        [attribs setObject:[NSColor lightGrayColor]
                    forKey:NSForegroundColorAttributeName];
        // XXX - how to use bordercolor now? 
        NSString *label = _frequencies[i] < 1000
        ? [NSString stringWithFormat:@"%d", _frequencies[i]]
        : [NSString stringWithFormat:@"%dK", _frequencies[i]/1000]; 
        NSAttributedString * string = [[[NSAttributedString alloc] initWithString:label 
                                                                       attributes:attribs]
                                       autorelease];
        NSPoint point;
        point.x = frequencyRect.origin.x+4;
        point.y = 4;
        [string drawAtPoint:point];
    }
    [imagePin deliverData:[CIImage imageWithCGLayer:pathLayers[pathIndex]]];
}

- (void)newSample:(VJXAudioBuffer *)sample
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
                    UInt32 numFrames = [sample numFrames];
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
        [analyzer processForwards:[sample numFrames] input:deinterleavedBuffer];

        [analyzer getMagnitude:spectrumBuffer min:minAmp max:maxAmp];
        
        for (UInt32 i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {	// for each frequency
            int offset = _frequencies[i]*numBins/44100*analyzer.numChannels;
            Float32 value = (((Float32 *)(spectrumBuffer->mBuffers[0].mData))[offset] +
                             ((Float32 *)(spectrumBuffer->mBuffers[1].mData))[offset]) * 0.5;
            if (value < 0.0)
                value = 0.0;
            
            NSNumber *numberValue = [NSNumber numberWithFloat:value];
            [(VJXOutputPin *)[frequencyPins objectAtIndex:i] deliverData:numberValue];
            frequencyValues[i] = value;
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
    NSMutableArray *pinNames = [[NSMutableArray alloc] init];
    for (VJXOutputPin *pin in frequencyPins) {
        [pinNames addObject:pin.name];
    }
    [pinNames addObject:@"active"];
    [pinNames addObject:@"image"];
    [pinNames addObject:@"imageSize"];
    return [pinNames autorelease];
}

#pragma mark V8
using namespace v8;

static v8::Handle<Value>frequencies(const Arguments& args)
{
    HandleScope handleScope;
    /*
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    VJXAudioSpectrumAnalyzer *entity = (VJXAudioSpectrumAnalyzer *)wrap->Value();
    */
    v8::Handle<Array> list = v8::Array::New(kVJXAudioSpectrumNumFrequencies);
    for (int i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {
        list->Set(i, v8::Integer::New(_frequencies[i]));
    }
    return handleScope.Close(list);
}

static v8::Handle<Value> frequency(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    VJXAudioSpectrumAnalyzer *entity = (VJXAudioSpectrumAnalyzer *)wrap->Value();
    v8::Handle<Value> arg = args[0];
    int freq = args[0]->IntegerValue();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *label = freq < 1000
                    ? [NSString stringWithFormat:@"%d", freq]
                    : [NSString stringWithFormat:@"%dK", freq/1000];
    VJXPin *pin = [entity outputPinWithName:label];
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


+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    v8::Handle<v8::FunctionTemplate> entityTemplate = [super jsClassTemplate];
    entityTemplate->SetClassName(String::New("VideoLayer"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("frequencies", FunctionTemplate::New(frequencies));
    classProto->Set("frequency", FunctionTemplate::New(frequency));
    return handleScope.Close(entityTemplate);
}

@end
