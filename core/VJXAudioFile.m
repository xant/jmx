//
//  VJXAudioFile.m
//  VeeJay
//
//  Created by xant on 9/15/10.
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

#import "VJXAudioFile.h"
#import "VJXAudioBuffer.h"


@implementation VJXAudioFile

+ (id)audioFileWithURL:(NSURL *)url
{
    VJXAudioFile *obj = [[VJXAudioFile alloc] initWithURL:url];
    if (obj) // if the url is wrong init could return nil
        [obj autorelease];
    return obj;
}

- (id)initWithURL:(NSURL *)url
{
    OSStatus err = noErr;
    if (self = [super init]) {
        UInt32 thePropertySize = sizeof(fileFormat);

        err = ExtAudioFileOpenURL ( (CFURLRef)url, &audioFile );
        if (err != noErr) {
            // TODO - ErrorMessages
        }
        // Get the audio data format
        err = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &fileFormat);
        if (err != noErr) {
            // TODO - ErrorMessages
        }
    }
    if (err != noErr) {
        [self dealloc];
        return nil;
    }
    return self;
}

- (void)dealloc
{
    if (audioFile)
        ExtAudioFileDispose(audioFile);
    [super dealloc];
}

- (VJXAudioBuffer *)readFrame
{
    return [self readFrames:1];
}

- (VJXAudioBuffer *)readFrames:(NSUInteger)numFrames
{
    UInt32  thePropertySize;
    SInt64  theFileLengthInFrames = 0;
    OSStatus err = noErr;
    AudioStreamBasicDescription		theOutputFormat;
    void *data;
    VJXAudioBuffer *buffer = nil;

    // Set the client format to 32bit float data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = fileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = 2;
    theOutputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 4 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 4 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 32;
	
	// Set the desired client (output) data format
	err = ExtAudioFileSetProperty(audioFile, kExtAudioFileProperty_ClientDataFormat, sizeof(theOutputFormat), &theOutputFormat);
	if(err) {
        NSLog(@"MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %ld\n", err);
        return nil;
    }
	
	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if(err) {
        NSLog(@"MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %ld\n", err);
        return nil;
    }
	
	// Read all the data into memory
	//UInt32 theFramesToRead = (UInt32)theFileLengthInFrames;		
	UInt32 dataSize = numFrames * theOutputFormat.mBytesPerFrame;
	data = malloc(dataSize);
	if (data)
	{
        UInt32 nFrames = numFrames;
		AudioBufferList		*theDataBuffer = calloc(1, sizeof(AudioBufferList));
		theDataBuffer->mNumberBuffers = 1;
		theDataBuffer->mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer->mBuffers[0].mNumberChannels = 2;
		theDataBuffer->mBuffers[0].mData = data;

        // Read the data into an AudioBufferList
		err = ExtAudioFileRead(audioFile, &nFrames, theDataBuffer);
		if(err == noErr)
		{
            if (nFrames) {
                buffer = [VJXAudioBuffer audioBufferWithCoreAudioBufferList:theDataBuffer 
                                                                  andFormat:(AudioStreamBasicDescription *)&theOutputFormat
                                                                       copy:NO
                                                              freeOnRelease:YES];
            }
		}
		else 
		{ 
			// failure
			free (data);
            free(theDataBuffer);
			NSLog(@"MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld\n", err);
            return nil;
		}	
    }
    return buffer;
}

- (BOOL)seekToOffset:(NSInteger)offset
{
    OSStatus err = ExtAudioFileSeek (audioFile, offset);
    if (err != noErr) {
        // TODO - Error messages
        return NO;
    }
    return YES;
}


- (NSInteger)currentOffset
{
    SInt64 offset;
    OSStatus err = ExtAudioFileTell(audioFile,&offset);
    if (err != noErr) {
        // TODO - error messages
    }
    return offset;
}

- (NSUInteger)numChannels
{
    return fileFormat.mChannelsPerFrame;
}

- (NSUInteger)sampleRate
{
    return fileFormat.mSampleRate;
}

- (NSUInteger)bitsPerChannel
{
    return 32; // XXX
}

- (NSInteger)numFrames
{
    UInt32 thePropertySize = sizeof(SInt64);
    SInt64 numFrames;
    OSStatus err = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &numFrames);
    if (err != noErr) {
        // TODO - ErrorMessages
        return 0;
    }
    return numFrames;
}

@end
