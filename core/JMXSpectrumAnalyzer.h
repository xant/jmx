//
//  JMXSpectrumAnalyzer.h
//  JMX
//
//  Created by xant on 9/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//
/*!
 @header JMXSpectrumAnalyzer.h
 @abstract base implementation for spectrum analysis using the fft provided by the Accelerate framework
 */
#import <Cocoa/Cocoa.h>
#if !defined(__COREAUDIO_USE_FLAT_INCLUDES__)
#include <CoreAudio/CoreAudioTypes.h>
#include <CoreFoundation/CoreFoundation.h>
#else
#include <CoreAudioTypes.h>
#include <CoreFoundation.h>
#endif

#include <Accelerate/Accelerate.h>

/*!
 @typedef JMXSpectralFunction
 @abstract callback which will be called while processing the spectral buffer (can be set using @link setSpectralFunction:clientData: @/link)
 */
typedef void (*JMXSpectralFunction)(DSPSplitComplex* spectra, UInt32 numSpectra, void* inUserData);

@class JMXSpectralChannel;

/*!
 @class JMXSpectrumAnalyzer
 @abstract base implementation for spectrum analysis using the fft provided by the Accelerate framework
 */
@interface JMXSpectrumAnalyzer : NSObject {
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
    
	JMXSpectralFunction spectralFunction;
	void *userData;
}

/*!
 @property numChannels
 @abstract the number of channels in the buffer
 */
@property (readonly) UInt32 numChannels;

/*!
 @method initWithSize:hopSize:channels:maxFrames:
 @param fftSize size of the fft
 @param hopSize size of the hops usually fft/2
 @param numChannels the number of channels in the buffer (use deinterleaved buffers to obtain decent results)
 @param maxFrames the max number of frames which can be store in the in internal buffer
 @return the initilized instance
 */
- (id)initWithSize:(UInt32)fftSize hopSize:(UInt32)hopSize channels:(UInt32)numChannels maxFrames:(UInt32)maxFrames;
/*!
 @method setSpectralFunction:clientData:
 @abstract set a function to be called while processing the spectral buffer
 @param inFunction the @link JMXSpectralFunction @/link to call while processing the spectral buffer
 @param inUserData the data to pass to the registered function each time it's called
 */
- (void)setSpectralFunction:(JMXSpectralFunction)inFunction clientData:(void*)inUserData;
/*!
 @method reset
 @abstract reset the internal buffer
 */
- (void)reset;
/*!
 @method process:input:output:
 @param numFrames the number of frames to process
 @param input the input buffer
 @param output the output buffer (where processed data is put)
 */
- (void)process:(UInt32)numFrames input:(AudioBufferList *)input output:(AudioBufferList *)output;
/*!
 @method hanningWindow
 @abstract compute the hanningWindow
 */
- (void)hanningWindow; // set up a hanning window
/*!
 @method sineWindow
 @abstract comput the sineWindow
 */
- (void)sineWindow;
/*!
 @method getFrequencies:rate
 @param freqs the output buffer where to store the extracted frequencies
 @param sampleRate the sample rate
 */
- (void)getFrequencies:(Float32*)freqs rate:(Float32)sampleRate; // only for processed forward
/*!
 @method getMagnitude:min:max
 @param inCopy
 @param min
 @param max
 */
- (void)getMagnitude:(AudioBufferList*)inCopy min:(Float32*)min max:(Float32*)max; // only for processed forward
/*!
 @method processForwards:input:
 @param inNumFrames
 @param inInput
 @return YES if buffer was processed successfully, NO if an error occurred
 */
- (BOOL)processForwards:(UInt32)inNumFrames input:(AudioBufferList*)inInput;
/*!
 @method processBackwards:input:
 @param inNumFrames
 @param outOutput
 @return YES if buffer was processed successfully, NO if an error occurred
 */
- (BOOL)processBackwards:(UInt32)inNumFrames output:(AudioBufferList*)outOutput;
/*!
 @method printSpectralBufferList
 @abstract print the spectral buffer on stdout for debugging purposes 
 */
- (void)printSpectralBufferList;
@end
