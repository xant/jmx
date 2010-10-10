//
//  VJXAudioSpectrumAnalyzer.m
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioSpectrumAnalyzer.h"
#import "VJXSpectrumAnalyzer.h"
#import "VJXAudioBuffer.h"
#import "VJXAudioFormat.h"

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

#define kVJXAudioSpectrumNumFrequencies 15
static int frequencies[kVJXAudioSpectrumNumFrequencies] = { 16, 32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000, 32000, 64000, 128000, 256000 }; 

@implementation VJXAudioSpectrumAnalyzer

- (id)init
{
    if (self = [super init]) {
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
        blockSize = 512;
        numBins = blockSize>>1;
        converter = nil;
        
        // setup the buffer where the squared magnitude will be put into
        spectrumBuffer = calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
        spectrumBuffer->mNumberBuffers = 2;
        spectrumBuffer->mBuffers[0].mNumberChannels = 1;
        spectrumBuffer->mBuffers[0].mData = calloc(1, sampleSize * numBins);
        spectrumBuffer->mBuffers[0].mDataByteSize = sampleSize * numBins;
        spectrumBuffer->mBuffers[1].mNumberChannels = 1;
        spectrumBuffer->mBuffers[1].mData = calloc(1, sampleSize * numBins);
        spectrumBuffer->mBuffers[1].mDataByteSize = sampleSize * numBins;
        minAmp = (Float32*) calloc(2, sizeof(Float32));
        maxAmp = (Float32*) calloc(2, sizeof(Float32));
        
#if DEINTERLEAVE_BUFFER
        analyzer = [[VJXSpectrumAnalyzer alloc] initWithSize:blockSize hopSize:numBins channels:2 maxFrames:256];

        deinterleavedBuffer = calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
        deinterleavedBuffer->mNumberBuffers = 2;
        deinterleavedBuffer->mBuffers[0].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[0].mDataByteSize = sampleSize*256;
        deinterleavedBuffer->mBuffers[0].mData = calloc(1,sampleSize*256);
        deinterleavedBuffer->mBuffers[1].mNumberChannels = 1;
        deinterleavedBuffer->mBuffers[1].mDataByteSize = sampleSize*256;
        deinterleavedBuffer->mBuffers[1].mData = calloc(1,sampleSize*256);
#else
        analyzer = [[VJXSpectrumAnalyzer alloc] initWithSize:blockSize hopSize:numBins channels:1 maxFrames:256];
#endif
        
        // setup the frequency pins
        frequencyPins = [[NSMutableArray alloc] init];
        for (int i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {
            int freq = frequencies[i];
            NSString *pinName = freq < 1000
                              ? [NSString stringWithFormat:@"%dHz", freq]
                              : [NSString stringWithFormat:@"%dKhz", freq/1000]; 
            [frequencyPins addObject:[self registerOutputPin:pinName withType:kVJXNumberPin]];
        }
        
        // initialize the coregraphics context where to draw a graphical representation
        // of the audiospectrum
        //If you're only using this from within -drawRect:, you can use
        NSBitmapImageRep *imageStorage = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:nil
                                                                                 pixelsWide:640
                                                                                 pixelsHigh:480
                                                                              bitsPerSample:8
                                                                            samplesPerPixel:4
                                                                                   hasAlpha:YES
                                                                                   isPlanar:NO
                                                                             colorSpaceName:NSDeviceRGBColorSpace
                                                                                bytesPerRow:4*640
                                                                               bitsPerPixel:4*8];
        imageContext = [NSGraphicsContext graphicsContextWithBitmapImageRep:imageStorage];
        [imageStorage release];
        CGSize layersize;
        layersize.height = 480;
        layersize.width = 640;
        pathLayer = CGLayerCreateWithContext( [imageContext graphicsPort],
                                               layersize , NULL );
        currentImage = nil;
        imagePin = [self registerOutputPin:@"image" withType:kVJXImagePin];
    }
    return self;
}

- (void)dealloc
{
    free(spectrumBuffer->mBuffers[0].mData);
    free(spectrumBuffer->mBuffers[1].mData);
    free(spectrumBuffer);
#if DEINTERLEAVE_BUFFER
    free(deinterleavedBuffer->mBuffers[0].mData);
    free(deinterleavedBuffer->mBuffers[1].mData);
    free(deinterleavedBuffer);
#endif
    free(minAmp);
    free(maxAmp);
    if (currentImage)
        [currentImage release];
    CGLayerRelease(pathLayer);
    [imageContext release];
    [super dealloc];
}

- (void)newSample:(VJXAudioBuffer *)sample
{
    @synchronized(analyzer) {
        AudioBufferList *bufferList = sample.bufferList;
#if DEINTERLEAVE_BUFFER
        AudioStreamBasicDescription format = sample.format.audioStreamBasicDescription;
        UInt32 numFrames = bufferList->mBuffers[0].mDataByteSize / 
        format.mBytesPerFrame / 
        bufferList->mBuffers[0].mNumberChannels;
        // and then fill them up
        for (j = 0; j < numFrames; j++) {
            uint8_t *frame = ((uint8_t *)bufferList->mBuffers[0].mData) +
            (j*4*bufferList->mBuffers[0].mNumberChannels);
            memcpy(deinterleavedBuffer->mBuffers[0].mData+(j*4), frame, 4);
            memcpy(deinterleavedBuffer->mBuffers[1].mData+(j*4), frame+ 4, 4);
        }
    
       // NSLog(@"%d", [sample numFrames]);
        [analyzer processForwards:[sample numFrames] input:deinterleavedBuffer];
#else
        [analyzer processForwards:[sample numFrames]*2 input:bufferList];
#endif

        [analyzer getMagnitude:spectrumBuffer min:minAmp max:maxAmp];
        NSGraphicsContext *pathContext = nil;
        
        
        pathContext = [NSGraphicsContext
                       graphicsContextWithGraphicsPort:CGLayerGetContext( pathLayer )
                       flipped:NO];
       // NSGraphicsContext *currentContext = [myWindow graphicsContext];

        [NSGraphicsContext setCurrentContext:pathContext];
        
        NSRect imageRect;
        imageRect.origin.x = 0;
        imageRect.origin.y = 0;
        imageRect.size.width = 640;
        imageRect.size.height = 480;
        NSBezierPath *path = [[NSBezierPath alloc] init];
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
        [[NSColor blackColor] setStroke];
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        //[transform translateXBy:0.5 yBy:0.5];
        [path appendBezierPathWithRoundedRect:imageRect xRadius:4.0 yRadius:4.0];
        [path transformUsingAffineTransform:transform];
        [path fill];
        [path stroke];
        [path release];
        
        for (UInt32 i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {	// for each frequency
            int offset = frequencies[i]*numBins/44100;
            Float32 value = sqrt(((Float32 *)spectrumBuffer->mBuffers[0].mData)[offset]);
            if (value < 0.0)
                value = 0.0;
            [(VJXPin *)[frequencyPins objectAtIndex:i] deliverSignal:[NSNumber numberWithFloat:value]];

             
             //Draw your bezier paths here
            NSRect frequencyRect;
            frequencyRect.origin.x = i*50;
            frequencyRect.origin.y = 0;
            frequencyRect.size.width = 50;
            frequencyRect.size.height = value * 50;
            
            NSBezierPath *path = [[NSBezierPath alloc] init];
            [[NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:0.5] setFill];

            [[NSColor yellowColor] setStroke];
            NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
            //[transform translateXBy:0.5 yBy:0.5];
            [path appendBezierPathWithRoundedRect:frequencyRect xRadius:4.0 yRadius:4.0];
            [path transformUsingAffineTransform:transform];
            [path fill];
            [path stroke];
            [path release];
            //NSLog(@"%d - %f \n", frequencies[i], ((Float32 *)spectrumBuffer->mBuffers[0].mData)[offset]);
        }
     //    [NSGraphicsContext setCurrentContext:currentContext];
         
         if (currentImage)
             [currentImage release];
         currentImage = [[CIImage imageWithCGLayer:pathLayer] retain];
        [imagePin deliverSignal:currentImage];
    }
    
}

// override outputPins to return them properly sorted
- (NSArray *)outputPins
{
    NSMutableArray *pinNames = [[NSMutableArray alloc] init];
    for (VJXPin *pin in frequencyPins) {
        [pinNames addObject:pin.name];
    }
    [pinNames addObject:@"active"];
    [pinNames addObject:@"image"];
    return pinNames;
}

@end
