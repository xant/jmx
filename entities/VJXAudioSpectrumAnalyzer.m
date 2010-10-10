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

#define kVJXAudioSpectrumImageWidth 400
#define kVJXAudioSpectrumImageHeight 300

#define kVJXAudioSpectrumNumFrequencies 14
static int frequencies[kVJXAudioSpectrumNumFrequencies] = { 30, 80, 125, 250, 350, 500, 750, 1000, 2000, 3000, 4000, 5000, 8000, 16000 }; 

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
        blockSize = 1024; // double the num of bins
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
        
        analyzer = [[VJXSpectrumAnalyzer alloc] initWithSize:blockSize hopSize:numBins channels:2 maxFrames:512];

        deinterleavedBuffer = calloc(1, sizeof(AudioBufferList) + sizeof(AudioBuffer));
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
        pathLayer = CGLayerCreateWithContext( [imageContext graphicsPort],
                                               layerSize , NULL );
        currentImage = nil;
        imagePin = [self registerOutputPin:@"image" withType:kVJXImagePin];
        imageSizePin = [self registerOutputPin:@"imageSize" withType:kVJXSizePin];
        [imageSizePin setContinuous:NO];
        [imageSizePin deliverSignal:[VJXSize sizeWithNSSize:layerSize]];
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
    CGLayerRelease(pathLayer);
    [imageContext release];
    [super dealloc];
}

- (void)newSample:(VJXAudioBuffer *)sample
{
    if (!sample)
        return;
    @synchronized(analyzer) {
        AudioBufferList *bufferList = sample.bufferList;
        switch (bufferList->mBuffers[0].mNumberChannels == 2) {
            case 1:
                {
                    UInt32 sizeToCopy = MIN(bufferList->mBuffers[0].mDataByteSize, 
                                            deinterleavedBuffer->mBuffers[0].mDataByteSize);
                    memcpy(deinterleavedBuffer->mBuffers[0].mData, bufferList->mBuffers[0].mData, sizeToCopy);
                    memcpy(deinterleavedBuffer->mBuffers[1].mData, bufferList->mBuffers[0].mData, sizeToCopy);
                break;
                }
            case 2:
                {
                    AudioStreamBasicDescription format = sample.format.audioStreamBasicDescription;
                    UInt32 numFrames = bufferList->mBuffers[0].mDataByteSize / 
                    format.mBytesPerFrame / 
                    bufferList->mBuffers[0].mNumberChannels;
                    for (int j = 0; j < numFrames; j++) {
                        uint8_t *frame = ((uint8_t *)bufferList->mBuffers[0].mData) +
                        (j*4*bufferList->mBuffers[0].mNumberChannels);
                        memcpy(deinterleavedBuffer->mBuffers[0].mData+(j*4), frame, 4);
                    }
                }
                break;
            default:
                // TODO - error messages
                return;
        }
        [analyzer processForwards:[sample numFrames] input:deinterleavedBuffer];

        [analyzer getMagnitude:spectrumBuffer min:minAmp max:maxAmp];
        NSGraphicsContext *pathContext = nil;
        
        
        pathContext = [NSGraphicsContext
                       graphicsContextWithGraphicsPort:CGLayerGetContext( pathLayer )
                       flipped:NO];

        [NSGraphicsContext setCurrentContext:pathContext];
        
        NSRect imageRect;
        imageRect.origin.x = 0;
        imageRect.origin.y = 0;
        imageRect.size.width = kVJXAudioSpectrumImageWidth;
        imageRect.size.height = kVJXAudioSpectrumImageHeight;
        NSBezierPath *path = [[NSBezierPath alloc] init];
        [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];
        [[NSColor blackColor] setStroke];
        NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
        [path appendBezierPathWithRoundedRect:imageRect xRadius:4.0 yRadius:4.0];
        [path transformUsingAffineTransform:transform];
        [path fill];
        [path stroke];
        [path release];
        
        for (UInt32 i = 0; i < kVJXAudioSpectrumNumFrequencies; i++) {	// for each frequency
            int offset = frequencies[i]*numBins/44100;
            Float32 value = ((Float32 *)(spectrumBuffer->mBuffers[0].mData))[offset] +
                            ((Float32 *)(spectrumBuffer->mBuffers[1].mData))[offset];
            if (value < 0.0)
                value = 0.0;
            [(VJXPin *)[frequencyPins objectAtIndex:i] deliverSignal:[NSNumber numberWithFloat:value]];

             
             //Draw your bezier paths here
            int barWidth = imageRect.size.width/kVJXAudioSpectrumNumFrequencies;
            NSRect frequencyRect;
            frequencyRect.origin.x = i*barWidth;
            frequencyRect.origin.y = 0;
            frequencyRect.size.width = barWidth;
            frequencyRect.size.height = MIN(value, imageRect.size.height-5);
            
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
            NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
            [attribs
             setObject:[NSFont labelFontOfSize:10]
             forKey:NSFontAttributeName
             ];
            [attribs
             setObject:[NSColor blueColor]
             forKey:NSForegroundColorAttributeName
             ];
            // XXX - how to use bordercolor now? 
            NSString *label = frequencies[i] < 1000
                              ? [NSString stringWithFormat:@"%d", frequencies[i]]
                              : [NSString stringWithFormat:@"%dK", frequencies[i]/1000]; 
            NSAttributedString * string = [[[NSAttributedString alloc] initWithString:label 
                                                                           attributes:attribs]
                                           autorelease];
            NSPoint point;
            point.x = frequencyRect.origin.x+4;
            point.y = 4;
            [string drawAtPoint:point];
        }
         
        @synchronized(self) {
            if (currentImage)
                 [currentImage release];
             currentImage = [[CIImage imageWithCGLayer:pathLayer] retain];
            [imagePin deliverSignal:currentImage];
        }
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
    [pinNames addObject:@"imageSize"];
    return pinNames;
}

@end
