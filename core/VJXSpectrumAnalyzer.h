//
//  VJXSpectrumAnalyzer.h
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

#import <Cocoa/Cocoa.h>
#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
#include <CoreAudio/CoreAudioTypes.h>
#include <CoreFoundation/CoreFoundation.h>
#else
#include <CoreAudioTypes.h>
#include <CoreFoundation.h>
#endif

#include <Accelerate/Accelerate.h>
typedef void (*VJXSpectralFunction)(DSPSplitComplex* spectra, UInt32 numSpectra, void* inUserData);

@class VJXSpectralChannel;

@interface VJXSpectrumAnalyzer : NSObject {
@protected
	UInt32 hopSize;
	UInt32 numChannels;
	UInt32 maxFrames;
    UInt32 fftSize;
    UInt32 log2FFTSize;

	FFTSetup fftSetup;
    
	NSData *window;

    UInt32 numberSpectra;
	DSPSplitComplex *dspSplitComplex;
    NSMutableArray *channels;
    
	VJXSpectralFunction spectralFunction;
	void *userData;
}

- (id)initWithSize:(UInt32)fftSize hopSize:(UInt32)hopSize channels:(UInt32)numChannels maxFrames:(UInt32)maxFrames;
- (void)setSpectralFunction:(VJXSpectralFunction)inFunction clientData:(void*)inUserData;
//CASpectralProcessor(UInt32 inFFTSize, UInt32 inHopSize, UInt32 inNumChannels, UInt32 inMaxFrames);
- (void)reset;
- (void)process:(UInt32)numFrames input:(AudioBufferList *)input output:(AudioBufferList *)output;

/*
UInt32 FFTSize() const { return mFFTSize; }
UInt32 MaxFrames() const { return mMaxFrames; }
UInt32 NumChannels() const { return mNumChannels; }
UInt32 HopSize() const { return mHopSize; }
Float32* Window() const { return mWindow; }
*/

- (void)hanningWindow; // set up a hanning window
- (void)sineWindow;

- (void)getFrequencies:(Float32*)freqs rate:(Float32)sampleRate; // only for processed forward
- (void)getMagnitude:(AudioBufferList*)inCopy min:(Float32*)min max:(Float32*)max; // only for processed forward

- (BOOL)processForwards:(UInt32)inNumFrames input:(AudioBufferList*)inInput;
- (BOOL)processBackwards:(UInt32)inNumFrames output:(AudioBufferList*)outOutput;

- (void)printSpectralBufferList;
@end
