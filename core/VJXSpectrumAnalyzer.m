//
//  VJXSpectrumAnalyzer.m
//  VeeJay
//
//  Created by xant on 9/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXSpectrumAnalyzer.h"

static __inline__ int CountLeadingZeroes(int arg) {
#if TARGET_CPU_PPC || TARGET_CPU_PPC64
	__asm__ volatile("cntlzw %0, %1" : "=r" (arg) : "r" (arg));
	return arg;
#elif TARGET_CPU_X86 || TARGET_CPU_X86_64
	__asm__ volatile(
                     "bsrl %0, %0\n\t"
                     "movl $63, %%ecx\n\t"
                     "cmove %%ecx, %0\n\t"
                     "xorl $31, %0" 
                     : "=r" (arg) 
                     : "0" (arg) : "%ecx"
                     );
	return arg;
#else
	if (arg == 0) return 32;
	return __builtin_clz(arg);
#endif
}

// count trailing zeroes
static inline UInt32 CountTrailingZeroes(UInt32 x)
{
	return 32 - CountLeadingZeroes(~x & (x-1));
}

// count leading ones
static inline UInt32 CountLeadingOnes(UInt32 x)
{
	return CountLeadingZeroes(~x);
}

// count trailing ones
static inline UInt32 CountTrailingOnes(UInt32 x)
{
	return 32 - CountLeadingZeroes(x & (~x-1));
}

// number of bits required to represent x.
static inline UInt32 NumBits(UInt32 x)
{
	return 32 - CountLeadingZeroes(x);
}

// base 2 log of next power of two greater or equal to x
static inline UInt32 Log2Ceil(UInt32 x)
{
	return 32 - CountLeadingZeroes(x - 1);
}

// next power of two greater or equal to x
static inline UInt32 NextPowerOfTwo(UInt32 x)
{
	return 1L << Log2Ceil(x);
}


#pragma mark VJXSpectralChannel

@interface VJXSpectralChannel : NSObject
{
    UInt32 bufLen;
    UInt32 fftLen;
    Float32 *inputBuf;
    Float32 *outputBuf;
    Float32 *fftBuf;
    Float32 *splitFFTBuf;
    UInt32 fftSize;
	UInt32 ioBufSize;
    UInt32 maxFrames;
    UInt32 inputPos;
	UInt32 outputPos;
	UInt32 inFFTPos;
	UInt32 outFFTPos;
    UInt32 inputSize;
    UInt32 ioMask;
	UInt32 fftMask; 
	UInt32 fftByteSize;

}

@property (readonly) Float32 *inputBuf;
@property (readonly) Float32 *outputBuf;
@property (readonly) Float32 *fftBuf;
@property (readonly) Float32 *splitFFTBuf;
@property (readonly) UInt32 inputSize;
@property (readonly) UInt32 fftSize;

- (id)initWithSize:(UInt32)size frames:(UInt32)numFrames;
- (void)reset;
- (void)copyInput:(AudioBuffer *)input frames:(UInt32)numFrames;
- (void)copyOutput:(AudioBuffer *)output frame:(UInt32)numFrames;
- (void)copyInputToFFT:(UInt32)mHopSize;
- (void)overlapAddOutput:(UInt32)mHopSize;
@end

@implementation VJXSpectralChannel

@synthesize inputBuf, outputBuf, fftBuf, splitFFTBuf;
@synthesize inputSize, fftSize;

- (id)initWithSize:(UInt32)size frames:(UInt32)numFrames
{
    if (self = [super init]) {
        fftSize = size;
        maxFrames = numFrames;
        ioBufSize = NextPowerOfTwo(fftSize + maxFrames);
        bufLen = sizeof(Float32)*ioBufSize;
        fftLen = sizeof(Float32)*fftSize;
        inputBuf = calloc(1, bufLen);
        outputBuf = calloc(1, bufLen);
        fftBuf = calloc(1, fftLen);
        splitFFTBuf = calloc(1, fftLen);
        fftMask = fftSize - 1;
        fftByteSize = fftSize * sizeof(Float32);
        ioBufSize = NextPowerOfTwo(fftSize + maxFrames);
        ioMask = ioBufSize - 1;
        inputSize = 0;
        inputPos = 0;
        outputPos = -fftSize & ioMask; 
        inFFTPos = 0;
        outFFTPos = 0;
        ioMask = ioBufSize - 1;
    }
    return self;
}

- (void)dealloc
{
    free(inputBuf);
    free(outputBuf);
    free(fftBuf);
    free(splitFFTBuf);
    [super dealloc];
}

- (void)reset
{
    memset((void *)inputBuf, 0, bufLen);
    memset((void *)outputBuf, 0, bufLen);
    memset((void *)fftBuf, 0, fftLen);
    inputPos = 0;
	outputPos = -fftSize & ioMask;
	inFFTPos = 0;
	outFFTPos = 0;
    //memset([splitFFTBuf bytes], 0, [splitFFTBuf length]);
}

- (void)copyInput:(AudioBuffer *)input frames:(UInt32)numFrames
{
    UInt32 numBytes = numFrames * sizeof(Float32);
    UInt32 firstPart = ioBufSize - inputPos;
    
	if (firstPart < numFrames) {
		UInt32 firstPartBytes = firstPart * sizeof(Float32);
		UInt32 secondPartBytes = numBytes - firstPartBytes;
        memcpy(inputBuf+ inputPos, input->mData, firstPartBytes);
        memcpy(inputBuf, (UInt8*)input->mData + firstPartBytes, secondPartBytes);
	} else {
        memcpy(inputBuf+ inputPos, input->mData, numBytes);
	}
	//printf("CopyInput %g %g\n", mChannels[0].mInputBuf[mInputPos], mChannels[0].mInputBuf[(mInputPos + 200) & mIOMask]);
	//printf("CopyInput mInputPos %u   mIOBufSize %u\n", (unsigned)mInputPos, (unsigned)mIOBufSize);
	inputSize += numFrames;
	inputPos = (inputPos + numFrames) & ioMask;    
}

- (void)copyOutput:(AudioBuffer *)output frame:(UInt32)numFrames
{
     //printf("->CopyOutput %g %g\n", mChannels[0].mOutputBuf[mOutputPos], mChannels[0].mOutputBuf[(mOutputPos + 200) & mIOMask]);
     //printf("CopyOutput mOutputPos %u\n", (unsigned)mOutputPos);
    if (output->mDataByteSize) {
        UInt32 numBytes = numFrames * sizeof(Float32);
        UInt32 firstPart = ioBufSize - outputPos;
        if (firstPart < numFrames) {
            UInt32 firstPartBytes = firstPart * sizeof(Float32);
            UInt32 secondPartBytes = numBytes - firstPartBytes;
            memcpy(output->mData, (Float32 *)outputBuf+ outputPos, firstPartBytes);
            memcpy((UInt8*)output->mData + firstPartBytes, (Float32 *)outputBuf, secondPartBytes);
            memset(outputBuf+ outputPos, 0, firstPartBytes);
            memset(outputBuf, 0, secondPartBytes);
        } else {
            memcpy(output->mData, outputBuf+ outputPos, numBytes);
            memset(outputBuf+ outputPos, 0, numBytes);
        }
        //printf("<-CopyOutput %g %g\n", ((Float32*)outOutput->mBuffers[0].mData)[0], ((Float32*)outOutput->mBuffers[0].mData)[200]);
        outputPos = (outputPos + numFrames) & ioMask;
    }
}

- (void)copyInputToFFT:(UInt32)mHopSize
{
    //printf("CopyInputToFFT mInFFTPos %u\n", (unsigned)mInFFTPos);
    UInt32 firstPart = ioBufSize - inFFTPos;
	UInt32 firstPartBytes = firstPart * sizeof(Float32);
	if (firstPartBytes < fftByteSize) {
		UInt32 secondPartBytes = fftByteSize - firstPartBytes;
        memcpy(fftBuf, inputBuf + inFFTPos, firstPartBytes);
        memcpy((UInt8*)fftBuf + firstPartBytes, inputBuf, secondPartBytes);
	} else {
        memcpy(fftBuf, inputBuf+ inFFTPos, fftByteSize);
	}
	inputSize -= mHopSize;
	inFFTPos = (inFFTPos + mHopSize) & ioMask;
	//printf("CopyInputToFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)overlapAddOutput:(UInt32)mHopSize
{
    //printf("OverlapAddOutput mOutFFTPos %u\n", (unsigned)mOutFFTPos);
	UInt32 firstPart = ioBufSize - outFFTPos;
	if (firstPart < fftSize) {
		UInt32 secondPart = fftSize - firstPart;
        float* out1 = (Float32 *)outputBuf + outFFTPos;
        vDSP_vadd(out1, 1, (Float32 *)fftBuf, 1, out1, 1, firstPart);
        float* out2 = (Float32 *)outputBuf;
        vDSP_vadd(out2, 1, (Float32 *)fftBuf + firstPart, 1, out2, 1, secondPart);
	} else {
        float* out1 = (Float32 *)outputBuf + outFFTPos;
        vDSP_vadd(out1, 1, (Float32 *)fftBuf, 1, out1, 1, fftSize);
	}
	//printf("OverlapAddOutput %g %g\n", mChannels[0].mOutputBuf[mOutFFTPos], mChannels[0].mOutputBuf[(mOutFFTPos + 200) & mIOMask]);
	outFFTPos = (outFFTPos + mHopSize) & ioMask;
}

@end

#pragma mark VJXSpectrumAnalyzer

@interface VJXSpectrumAnalyzer (Private)

- (void)doWindowing;
- (void)doFwdFFT;
- (void)doInvFFT;
- (void)overlapAddOutput;
- (void)processSpectrum;
- (void)reset;
- (void)copyInput:(AudioBufferList *)input frames:(UInt32)numFrames;
- (void)copyOutput:(AudioBufferList *)output frames:(UInt32)numFrames;
- (void)copyInputToFFT:(UInt32)hopSize;
@end

@implementation VJXSpectrumAnalyzer
#include <vecLib/vectorOps.h>

@synthesize numChannels;
#define OFFSETOF(class, field)((size_t)&((class*)0)->field)

- (id)initWithSize:(UInt32)size hopSize:(UInt32)hop channels:(UInt32)channelsNum maxFrames:(UInt32)frames
{
    if (self = [super init]) {
        int i;

        fftSize = size; // size of the fft output
        hopSize = hop; // size of 1 hop
        numChannels = channelsNum;
        maxFrames = frames;
        log2FFTSize = Log2Ceil(fftSize); 
        spectralFunction = 0;
        userData = 0;
        window = calloc(1, fftSize * sizeof(Float32));
        [self sineWindow]; // set default window.
        
        channels = [[NSMutableArray alloc] init];
        numberSpectra = numChannels;
        dspSplitComplex = calloc(numChannels, sizeof(DSPSplitComplex));
        for (i = 0; i < numChannels; i++) {
            VJXSpectralChannel *channel = [[VJXSpectralChannel alloc] initWithSize:(UInt32)fftSize frames:(UInt32)maxFrames];
            dspSplitComplex[i].realp = channel.splitFFTBuf;
            dspSplitComplex[i].imagp = channel.splitFFTBuf + (fftSize >> 1); // XXX
            [channels addObject:channel];
            [channel release]; // the channel will be released as soon as it will be removed from the NSArray
        }
        
        fftSetup = vDSP_create_fftsetup (log2FFTSize, FFT_RADIX2);
    } else {
        [self dealloc];
        self = nil;
    }
	return self;
}

- (void)dealloc
{
    while ([channels count]) {
        [channels removeLastObject];
    }
    if (window)
        free(window);
	vDSP_destroy_fftsetup(fftSetup);
    [super dealloc];
}

- (void)reset
{
    for (int i = 0; i < [channels count]; i++) 
        [[channels objectAtIndex:i] reset];
}

const double two_pi = 2. * M_PI;

-(void)hanningWindow
{ 
    Float32 *data = (Float32 *)window;
	// this is also vector optimized
	double w = two_pi / (double)(fftSize - 1);
	for (UInt32 i = 0; i < fftSize; i++)
	{
		data[i] = (0.5 - 0.5 * cos(w * (double)i));	
	}
}

- (void)sineWindow
{
    Float32 *data = (Float32 *)window;
	double w = M_PI / (double)(fftSize - 1);
	for (UInt32 i = 0; i < fftSize; i++)
	{
		data[i] = sin(w * (double)i);
	}
}

- (UInt32)inputSize
{
    // XXX - we query the first channel for the size.
    //       at the moment all channels will be aligned ...
    //       it would be better to keep offsets and sizes in this container
    //       instead of duplicating them among all the channels.
    //       Perhaps removing an indirection layer would be a good idea
    VJXSpectralChannel *channel = [channels objectAtIndex:0];
    if (channel)
        return channel.inputSize;
    return 0;
}

- (void)copyInput:(AudioBufferList *)input frames:(UInt32)numFrames
{
    int i;
    int channelsNum = MIN([channels count], input->mNumberBuffers);
    // TODO - deinterleave
    for (i = 0; i < channelsNum; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel copyInput:&input->mBuffers[i] frames:numFrames];
    }
}

- (void)copyOutput:(AudioBufferList *)output frames:(UInt32)numFrames
{
    int i;
    
    for (i = 0; i < [channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel copyInput:&output->mBuffers[i] frames:numFrames];
    }
}


- (void)copyInputToFFT:(UInt32)hop
{
    int i;
    for (i = 0; i < [channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel copyInputToFFT:hop];
    }
}

- (void)printSpectralBufferList
{
	for (UInt32 i=0; i<[channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        UInt32 half = channel.fftSize >> 1;
		DSPSplitComplex	*freqData = &dspSplitComplex[i];
        
		for (UInt32 j=0; j<half; j++){
			NSLog(@" bin[%d]: %lf + %lfi\n", (int) j, freqData->realp[j], freqData->imagp[j]);
		}
	}
}

- (void)process:(UInt32)numFrames input:(AudioBufferList *)input output:(AudioBufferList *)output
{
	// copy from buffer list to input buffer
	[self copyInput:input frames:numFrames];
	
	// if enough input to process, then process.
	while ([self inputSize] >= fftSize) 
	{
		[self copyInputToFFT:hopSize]; // copy from input buffer to fft buffer
		[self doWindowing];
		[self doFwdFFT];
		[self processSpectrum];
		[self doInvFFT];
		[self doWindowing];
		[self overlapAddOutput];
	}
    
	// copy from output buffer to buffer list
	[self copyOutput:output frames:numFrames];
}

- (void)doWindowing
{
	Float32 *win = (Float32 *)window;
	if (!win) return;
	for (UInt32 i = 0; i < numChannels; i++) {
		Float32 *x = (Float32 *)((VJXSpectralChannel *)[channels objectAtIndex:i]).fftBuf;
		vDSP_vmul(x, 1, win, 1, x, 1, fftSize);
	}
	//printf("DoWindowing %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)overlapAddOutput
{
    int i;
    for (i = 0; i < [channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel overlapAddOutput:hopSize];
    }
}


- (void)doFwdFFT
{
    UInt32 i;
	//printf("->DoFwdFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
	UInt32 half = fftSize >> 1;
	for (i=0; i<[channels count]; i++) 
	{
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        vDSP_ctoz((DSPComplex*)channel.fftBuf, 2, &dspSplitComplex[i], 1, half);
        vDSP_fft_zrip(fftSetup, &dspSplitComplex[i], 1, log2FFTSize, FFT_FORWARD);
	}
	//printf("<-DoFwdFFT %g %g\n", direction, mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)doInvFFT
{
	//printf("->DoInvFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
	UInt32 half = fftSize >> 1;
	for (UInt32 i = 0; i < numChannels; i++) 
	{
		vDSP_fft_zrip(fftSetup, &dspSplitComplex[i], 1, log2FFTSize, FFT_INVERSE);
		vDSP_ztoc(&dspSplitComplex[i], 1, (DSPComplex*)((VJXSpectralChannel *)[channels objectAtIndex:i]).fftBuf, 2, half);		
		float scale = 0.5 / fftSize;
		vDSP_vsmul(((VJXSpectralChannel *)[channels objectAtIndex:i]).fftBuf, 1, &scale, 
                   (void *)((VJXSpectralChannel *)[channels objectAtIndex:i]).fftBuf, 1, fftSize);
	}
	//printf("<-DoInvFFT %g %g\n", direction, mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)setSpectralFunction:(VJXSpectralFunction)inFunction clientData:(void*)inUserData
{
	spectralFunction = inFunction; 
	userData = inUserData;
}

- (void)processSpectrum
{
	if (spectralFunction)
		(spectralFunction)(dspSplitComplex, numberSpectra, userData);
}

#pragma mark ___Utility___

- (void)getMagnitude:(AudioBufferList*)list min:(Float32*)min max:(Float32*)max 
{	
	UInt32 half = fftSize >> 1;	
	for (UInt32 i=0; i<numChannels; i++) {
		DSPSplitComplex	*freqData = &dspSplitComplex[i];		
		
		Float32* b = (Float32*) list->mBuffers[i].mData;
		
		vDSP_zvabs(freqData,1,b,1,half); 		
        
		vDSP_maxmgv(b, 1, &max[i], half); 
 		vDSP_minmgv(b, 1, &min[i], half); 
		
    } 
}


- (void)getFrequencies:(Float32*)freqs rate:(Float32)sampleRate
{
	UInt32 half = fftSize >> 1;	
    
	for (UInt32 i=0; i< half; i++){
		freqs[i] = ((Float32)(i))*sampleRate/((Float32)fftSize);	
	}
}


- (BOOL)processForwards:(UInt32)inNumFrames input:(AudioBufferList*)inInput
{
    BOOL processed = NO;
    [self copyInput:inInput frames:inNumFrames];    
	// if enough input to process, then process.
	while ([self inputSize] >= fftSize) 
	{
		[self copyInputToFFT:hopSize]; // copy from input buffer to fft buffer
		[self doWindowing];
		[self doFwdFFT];
		[self processSpectrum]; // here you would copy the fft results out to a buffer indicated in mUserData, say for sonogram drawing
		processed = YES;
	}
	
	return processed;
}

- (BOOL)processBackwards:(UInt32)inNumFrames output:(AudioBufferList*)outOutput
{		
	
	[self processSpectrum];
	[self doInvFFT];
	[self doWindowing];
	[self overlapAddOutput];		
	
	// copy from output buffer to buffer list
	[self copyOutput:outOutput frames:inNumFrames];
	
	return YES;
}

@end
