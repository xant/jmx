//
//  VJXAudioFile.m
//  VeeJay
//
//  Created by xant on 9/15/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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

    // Set the client format to 16 bit signed integer (native-endian) data
	// Maintain the channel count and sample rate of the original source format
	theOutputFormat.mSampleRate = fileFormat.mSampleRate;
	theOutputFormat.mChannelsPerFrame = fileFormat.mChannelsPerFrame;
    
	theOutputFormat.mFormatID = kAudioFormatLinearPCM;
	theOutputFormat.mBytesPerPacket = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mFramesPerPacket = 1;
	theOutputFormat.mBytesPerFrame = 2 * theOutputFormat.mChannelsPerFrame;
	theOutputFormat.mBitsPerChannel = 16;
	theOutputFormat.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsSignedInteger;
	
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
        UInt32 nFrames;
		AudioBufferList		theDataBuffer;
		theDataBuffer.mNumberBuffers = 1;
		theDataBuffer.mBuffers[0].mDataByteSize = dataSize;
		theDataBuffer.mBuffers[0].mNumberChannels = theOutputFormat.mChannelsPerFrame;
		theDataBuffer.mBuffers[0].mData = data;

        // Read the data into an AudioBufferList
		err = ExtAudioFileRead(audioFile, &nFrames, &theDataBuffer);
		if(err == noErr)
		{
            buffer = [VJXAudioBuffer audioBufferWithCoreAudioBuffer:&theDataBuffer.mBuffers[0] 
                                                          andFormat:(AudioStreamBasicDescription *)&theOutputFormat];
		}
		else 
		{ 
			// failure
			free (data);
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
    return 16; // XXX
}

@end
