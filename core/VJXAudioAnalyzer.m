//
//  VJXAudioAnalyzer.m
//  VeeJay
//
//  Created by xant on 9/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioAnalyzer.h"

#pragma mark VJXSpectralBufferList
@interface VJXSpectralBufferlList
{
	UInt32 mNumberSpectra;
	DSPSplitComplex mDSPSplitComplex;
}
@property (assign) UInt32 mNumberSpectra;
@property (assign) DSPSplitComplex mDSPSplitComplex;
@end

@implementation VJXSpectralBufferlList
@synthesize mNumberSpectra, mDSPSplitComplex;
@end

#pragma mark VJXSpectralChannel

@interface VJXSpectralChannel 
{
    Float32 mInputBuf;		// log2ceil(FFT size + max frames)
    Float32 mOutputBuf;		// log2ceil(FFT size + max frames)
    Float32 mFFTBuf;		// FFT size
    Float32 mSplitFFTBuf;	// FFT size
}
@property (assign) Float32 mInputBuf;
@property (assign) Float32 mOutputBuf;
@property (assign) Float32 mFFTBuf;
@property (assign) Float32 mSplitFFTBuf;
@end

@implementation VJXSpectralChannel

@synthesize mInputBuf, mOutputBuf, mFFTBuf, mSplitFFTBuf;

@end


#pragma mark VJXAudioAnalyzer

@interface VJXAudioAnalyzer (Private)
- (void)copyInputFrames:(AudioBufferList*)frames count:(UInt32)numFrames;
- (void)copyInputToFFT;
- (void)doWindowing;
- (void)doFwdFFT;
- (void)doInvFFT;
- (void)overlapAddOutput;
- (void)copyOutputFrames:(AudioBufferList*)frames count:(UInt32)numFrames;
- (void)processSpectrum:(VJXSpectralBufferList*)inSpectra size:(UInt32)inFFTSize;
@end

@implementation VJXAudioAnalyzer

@end
