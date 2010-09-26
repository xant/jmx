//
//  VJXAudioAnalyzer.m
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

#import "VJXAudioAnalyzer.h"

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
    NSData *mInputBuf;		// log2ceil(FFT size + max frames)
    NSData *mOutputBuf;		// log2ceil(FFT size + max frames)
    NSData *mFFTBuf;		// FFT size
    NSData *mSplitFFTBuf;	// FFT size
    UInt32  mFFTSize;
	UInt32  mIOBufSize;
    UInt32  mMaxFrames;
    UInt32 mInputPos;
	UInt32 mOutputPos;
	UInt32 mInFFTPos;
	UInt32 mOutFFTPos;
    UInt32 mInputSize;
    UInt32 mIOMask;
	UInt32 mFFTMask; 
	UInt32 mFFTByteSize;

}
@property (readonly) NSData *mInputBuf;
@property (readonly) NSData *mOutputBuf;
@property (readonly) NSData *mFFTBuf;
@property (readonly) NSData *mSplitFFTBuf;
@property (readonly) UInt32 mInputSize;
@property (readonly) UInt32 mFFTSize;

- (id)initWithSize:(UInt32)fftSize frames:(UInt32)maxFrames;
- (void)reset;
- (void)copyInput:(AudioBuffer *)input frames:(UInt32)numFrames;
- (void)copyOutput:(AudioBuffer *)output frame:(UInt32)numFrames;
- (void)copyInputToFFT:(UInt32)mHopSize;
- (void)overlapAddOutput:(UInt32)mHopSize;
@end

@implementation VJXSpectralChannel

@synthesize mInputBuf, mInputSize, mOutputBuf, mFFTBuf, mFFTSize, mSplitFFTBuf;

- (id)initWithSize:(UInt32)fftSize frames:(UInt32)maxFrames
{
    if (self = [super init]) {
        mFFTSize = fftSize;
        mMaxFrames = maxFrames;
        mIOBufSize = NextPowerOfTwo(fftSize + maxFrames);
        UInt32 bufLen = sizeof(Float32)*mIOBufSize;
        UInt32 fftLen = sizeof(Float32)*mFFTSize;
        void *inputBuf = calloc(1, bufLen);
        void *outputBuf = calloc(1, bufLen);
        void *fftBuf = calloc(1, fftLen);
        void *splitFftBuf = calloc(1, fftLen);
        
        mInputBuf = [NSData dataWithBytesNoCopy:inputBuf length:bufLen freeWhenDone:YES];
        mOutputBuf = [NSData dataWithBytesNoCopy:outputBuf length:bufLen freeWhenDone:YES];
        mFFTBuf = [NSData dataWithBytesNoCopy:fftBuf length:fftLen freeWhenDone:YES];
        mSplitFFTBuf = [NSData dataWithBytesNoCopy:splitFftBuf length:fftLen freeWhenDone:YES];
        mFFTMask = mFFTSize - 1;
        mFFTByteSize = mFFTSize * sizeof(Float32);
        mIOBufSize = NextPowerOfTwo(mFFTSize + mMaxFrames);
        mIOMask = mIOBufSize - 1;
        mInputSize = 0;
        mInputPos = 0;
        mOutputPos = -mFFTSize & mIOMask; 
        mInFFTPos = 0;
        mOutFFTPos = 0;
        mIOMask = mIOBufSize - 1;
    }
    return self;
}

- (void)reset
{
    memset((void *)[mInputBuf bytes], 0, [mInputBuf length]);
    memset((void *)[mOutputBuf bytes], 0, [mOutputBuf length]);
    memset((void *)[mFFTBuf bytes], 0, [mFFTBuf length]);
    mInputPos = 0;
	mOutputPos = -mFFTSize & mIOMask;
	mInFFTPos = 0;
	mOutFFTPos = 0;
    //memset([mSplitFFTBuf bytes], 0, [mSplitFFTBuf length]);
}

- (void)copyInput:(AudioBuffer *)input frames:(UInt32)numFrames
{
    UInt32 numBytes = numFrames * sizeof(Float32);
    UInt32 firstPart = mIOBufSize - mInputPos;
    
	if (firstPart < numFrames) {
		UInt32 firstPartBytes = firstPart * sizeof(Float32);
		UInt32 secondPartBytes = numBytes - firstPartBytes;
        memcpy((Float32 *)[mInputBuf bytes]+ mInputPos, input->mData, firstPartBytes);
        memcpy((Float32 *)[mInputBuf bytes], (UInt8*)input->mData + firstPartBytes, secondPartBytes);
	} else {
		UInt32 numBytes = numFrames * sizeof(Float32);
        memcpy((Float32 *)[mInputBuf bytes]+ mInputPos, input->mData, numBytes);
	}
	//printf("CopyInput %g %g\n", mChannels[0].mInputBuf[mInputPos], mChannels[0].mInputBuf[(mInputPos + 200) & mIOMask]);
	//printf("CopyInput mInputPos %u   mIOBufSize %u\n", (unsigned)mInputPos, (unsigned)mIOBufSize);
	mInputSize += numFrames;
	mInputPos = (mInputPos + numFrames) & mIOMask;    
}

- (void)copyOutput:(AudioBuffer *)output frame:(UInt32)numFrames
{
     //printf("->CopyOutput %g %g\n", mChannels[0].mOutputBuf[mOutputPos], mChannels[0].mOutputBuf[(mOutputPos + 200) & mIOMask]);
     //printf("CopyOutput mOutputPos %u\n", (unsigned)mOutputPos);
     UInt32 numBytes = numFrames * sizeof(Float32);
     UInt32 firstPart = mIOBufSize - mOutputPos;
     if (firstPart < numFrames) {
         UInt32 firstPartBytes = firstPart * sizeof(Float32);
         UInt32 secondPartBytes = numBytes - firstPartBytes;
         memcpy(output->mData, (Float32 *)[mOutputBuf bytes]+ mOutputPos, firstPartBytes);
         memcpy((UInt8*)output->mData + firstPartBytes, (Float32 *)[mOutputBuf bytes], secondPartBytes);
         memset((Float32 *)[mOutputBuf bytes]+ mOutputPos, 0, firstPartBytes);
         memset((Float32 *)[mOutputBuf bytes], 0, secondPartBytes);
     } else {
         memcpy(output->mData, (Float32 *)[mOutputBuf bytes]+ mOutputPos, numBytes);
         memset((Float32 *)[mOutputBuf bytes]+ mOutputPos, 0, numBytes);
     }
     //printf("<-CopyOutput %g %g\n", ((Float32*)outOutput->mBuffers[0].mData)[0], ((Float32*)outOutput->mBuffers[0].mData)[200]);
     mOutputPos = (mOutputPos + numFrames) & mIOMask;
}

- (void)copyInputToFFT:(UInt32)mHopSize
{
    //printf("CopyInputToFFT mInFFTPos %u\n", (unsigned)mInFFTPos);
	UInt32 firstPart = mIOBufSize - mInFFTPos;
	UInt32 firstPartBytes = firstPart * sizeof(Float32);
	if (firstPartBytes < mFFTByteSize) {
		UInt32 secondPartBytes = mFFTByteSize - firstPartBytes;
        memcpy((Float32 *)[mFFTBuf bytes], (Float32 *)[mInputBuf bytes] + mInFFTPos, firstPartBytes);
        memcpy((UInt8*)[mFFTBuf bytes] + firstPartBytes, [mInputBuf bytes], secondPartBytes);
	} else {
        memcpy((Float32 *)[mFFTBuf bytes], (Float32 *)[mInputBuf bytes] + mInFFTPos, mFFTByteSize);
	}
	mInputSize -= mHopSize;
	mInFFTPos = (mInFFTPos + mHopSize) & mIOMask;
	//printf("CopyInputToFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)overlapAddOutput:(UInt32)mHopSize
{
    //printf("OverlapAddOutput mOutFFTPos %u\n", (unsigned)mOutFFTPos);
	UInt32 firstPart = mIOBufSize - mOutFFTPos;
	if (firstPart < mFFTSize) {
		UInt32 secondPart = mFFTSize - firstPart;
        float* out1 = (Float32 *)[mOutputBuf bytes] + mOutFFTPos;
        vDSP_vadd(out1, 1, (Float32 *)[mFFTBuf bytes], 1, out1, 1, firstPart);
        float* out2 = (Float32 *)[mOutputBuf bytes];
        vDSP_vadd(out2, 1, (Float32 *)[mFFTBuf bytes] + firstPart, 1, out2, 1, secondPart);
	} else {
        float* out1 = (Float32 *)[mOutputBuf bytes] + mOutFFTPos;
        vDSP_vadd(out1, 1, (Float32 *)[mFFTBuf bytes], 1, out1, 1, mFFTSize);
	}
	//printf("OverlapAddOutput %g %g\n", mChannels[0].mOutputBuf[mOutFFTPos], mChannels[0].mOutputBuf[(mOutFFTPos + 200) & mIOMask]);
	mOutFFTPos = (mOutFFTPos + mHopSize) & mIOMask;
}

@end

#pragma mark VJXAudioAnalyzer

@interface VJXAudioAnalyzer (Private)

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

@implementation VJXAudioAnalyzer
#include <vecLib/vectorOps.h>


#define OFFSETOF(class, field)((size_t)&((class*)0)->field)

- (id)initWithSize:(UInt32)fftSize hopSize:(UInt32)hopSize channels:(UInt32)numChannels maxFrames:(UInt32)maxFrames
{
    if (self = [super init]) {
        int i;

        mFFTSize = fftSize;
        mHopSize = hopSize;
        mNumChannels = numChannels;
        mMaxFrames = maxFrames;
        mLog2FFTSize = Log2Ceil(mFFTSize); 
        mSpectralFunction = 0;
        mUserData = 0;
        void *buffer = calloc(1, mFFTSize * sizeof(Float32));
        mWindow = [NSData dataWithBytesNoCopy:buffer length:mFFTSize freeWhenDone:YES];
        [self sineWindow]; // set default window.
        
        channels = [[NSMutableArray alloc] init];
        mNumberSpectra = numChannels;
        mDSPSplitComplex = calloc(numChannels, sizeof(DSPSplitComplex));
        for (i = 0; i < numChannels; i++) {
            VJXSpectralChannel *channel = [[VJXSpectralChannel alloc] initWithSize:(UInt32)fftSize frames:(UInt32)maxFrames];
            mDSPSplitComplex[i].realp = (void *)[channel.mSplitFFTBuf bytes];
            mDSPSplitComplex[i].imagp = (void *)[channel.mSplitFFTBuf bytes] + (fftSize >> 1); // XXX
            [channels addObject:channel];
            [channel release]; // the channel will be released as soon as it will be removed from the NSArray
        }
        
        mFFTSetup = vDSP_create_fftsetup (mLog2FFTSize, FFT_RADIX2);
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
	[mWindow release];
	vDSP_destroy_fftsetup(mFFTSetup);
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
    Float32 *data = (Float32 *)[mWindow bytes];
	// this is also vector optimized
	double w = two_pi / (double)(mFFTSize - 1);
	for (UInt32 i = 0; i < mFFTSize; i++)
	{
		data[i] = (0.5 - 0.5 * cos(w * (double)i));	
	}
}

- (void)sineWindow
{
    Float32 *data = (Float32 *)[mWindow bytes];
	double w = M_PI / (double)(mFFTSize - 1);
	for (UInt32 i = 0; i < mFFTSize; i++)
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
        return channel.mInputSize;
    return 0;
}

- (void)copyInput:(AudioBufferList *)input frames:(UInt32)numFrames
{
    int i;
    
    for (i = 0; i < [channels count]; i++) {
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


- (void)copyInputToFFT:(UInt32)hopSize
{
    int i;
    for (i = 0; i < [channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel copyInputToFFT:hopSize];
    }
}

- (void)printSpectralBufferList
{
	for (UInt32 i=0; i<[channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        UInt32 half = channel.mFFTSize >> 1;
		DSPSplitComplex	*freqData = &mDSPSplitComplex[i];
        
		for (UInt32 j=0; j<half; j++){
			printf(" bin[%d]: %lf + %lfi\n", (int) j, freqData->realp[j], freqData->imagp[j]);
		}
	}
}

- (void)process:(UInt32)numFrames input:(AudioBufferList *)input output:(AudioBufferList *)output
{
	// copy from buffer list to input buffer
	[self copyInput:input frames:numFrames];
	
	// if enough input to process, then process.
	while ([self inputSize] >= mFFTSize) 
	{
		[self copyInputToFFT:mHopSize]; // copy from input buffer to fft buffer
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
	Float32 *win = (Float32 *)[mWindow bytes];
	if (!win) return;
	for (UInt32 i=0; i<mNumChannels; i++) {
		Float32 *x = (Float32 *)[(NSData *)((VJXSpectralChannel *)[channels objectAtIndex:i]).mFFTBuf bytes];
		vDSP_vmul(x, 1, win, 1, x, 1, mFFTSize);
	}
	//printf("DoWindowing %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)overlapAddOutput
{
    int i;
    for (i = 0; i < [channels count]; i++) {
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        [channel overlapAddOutput:mHopSize];
    }
}


- (void)doFwdFFT
{
    UInt32 i;
	//printf("->DoFwdFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
	UInt32 half = mFFTSize >> 1;
	for (i=0; i<[channels count]; i++) 
	{
        VJXSpectralChannel *channel = [channels objectAtIndex:i];
        vDSP_ctoz((DSPComplex*)[channel.mFFTBuf bytes], 2, &mDSPSplitComplex[i], 1, half);
        vDSP_fft_zrip(mFFTSetup, &mDSPSplitComplex[i], 1, mLog2FFTSize, FFT_FORWARD);
	}
	//printf("<-DoFwdFFT %g %g\n", direction, mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)doInvFFT
{
	//printf("->DoInvFFT %g %g\n", mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
	UInt32 half = mFFTSize >> 1;
	for (UInt32 i=0; i<mNumChannels; i++) 
	{
		vDSP_fft_zrip(mFFTSetup, &mDSPSplitComplex[i], 1, mLog2FFTSize, FFT_INVERSE);
		vDSP_ztoc(&mDSPSplitComplex[i], 1, (DSPComplex*)[((VJXSpectralChannel *)[channels objectAtIndex:i]).mFFTBuf bytes], 2, half);		
		float scale = 0.5 / mFFTSize;
		vDSP_vsmul([((VJXSpectralChannel *)[channels objectAtIndex:i]).mFFTBuf bytes], 1, &scale, 
                   (void *)[((VJXSpectralChannel *)[channels objectAtIndex:i]).mFFTBuf bytes], 1, mFFTSize);
	}
	//printf("<-DoInvFFT %g %g\n", direction, mChannels[0].mFFTBuf()[0], mChannels[0].mFFTBuf()[200]);
}

- (void)setSpectralFunction:(VJXSpectralFunction)inFunction clientData:(void*)inUserData
{
	mSpectralFunction = inFunction; 
	mUserData = inUserData;
}

- (void)processSpectrum
{
	if (mSpectralFunction)
		(mSpectralFunction)(mDSPSplitComplex, mNumberSpectra, mUserData);
}

#pragma mark ___Utility___

- (void)getMagnitude:(AudioBufferList*)list min:(Float32*)min max:(Float32*)max 
{	
	UInt32 half = mFFTSize >> 1;	
	for (UInt32 i=0; i<mNumChannels; i++) {
		DSPSplitComplex	*freqData = &mDSPSplitComplex[i];		
		
		Float32* b = (Float32*) list->mBuffers[i].mData;
		
		vDSP_zvabs(freqData,1,b,1,half); 		
        
		vDSP_maxmgv(b, 1, &max[i], half); 
 		vDSP_minmgv(b, 1, &min[i], half); 
		
    } 
}


- (void)getFrequencies:(Float32*)freqs rate:(Float32)sampleRate
{
	UInt32 half = mFFTSize >> 1;	
    
	for (UInt32 i=0; i< half; i++){
		freqs[i] = ((Float32)(i))*sampleRate/((Float32)mFFTSize);	
	}
}


- (BOOL)processForwards:(UInt32)inNumFrames input:(AudioBufferList*)inInput
{
    BOOL processed = NO;
    [self copyInput:inInput frames:inNumFrames];    
	// if enough input to process, then process.
	while ([self inputSize] >= mFFTSize) 
	{
		[self copyInputToFFT:mHopSize]; // copy from input buffer to fft buffer
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
