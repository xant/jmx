//
//  JMXAudioFile.m
//  JMX
//
//  Created by xant on 9/15/10.
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

#import "JMXAudioFile.h"
#import "JMXAudioBuffer.h"

@interface JMXAudioFile () {
    ExtAudioFileRef audioFile;
    AudioStreamBasicDescription fileFormat;
    JMXAudioBuffer *samples[kJMXAudioFileBufferCount];
    OSSpinLock lock;
    UInt32 rOffset;
    UInt32 wOffset;
    BOOL isFilling;
    NSURL *url;
    BOOL overflow;
}
@end

@implementation JMXAudioFile
@synthesize url;

+ (id)audioFileWithURL:(NSURL *)url
{
    JMXAudioFile *obj = [[JMXAudioFile alloc] initWithURL:url];
    if (obj) // if the url is wrong init could return nil
        [obj autorelease];
    return obj;
}

- (void)fillBuffer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // we don't want to lock outside of the loop
    // in the worst case we will do an extra iteration ...
    // which is not a big deal (having a long-term lock is much worse)
    //NSLog(@"%@ buffering starts", self.url );
    BOOL eof = NO;
    while (wOffset-rOffset < kJMXAudioFileBufferCount/2 && !eof) {
        JMXAudioBuffer *newSample = [self readFrames:512];
        OSSpinLockLock(&lock);
        if (samples[wOffset%kJMXAudioFileBufferCount]) {
            [samples[wOffset%kJMXAudioFileBufferCount] release];
            samples[wOffset%kJMXAudioFileBufferCount] = nil;
        }
        if (newSample) {
            samples[wOffset++%kJMXAudioFileBufferCount] = [newSample retain];
            if (wOffset == 0)
                overflow = YES;
        } else {
            eof = YES;
        }
        OSSpinLockUnlock(&lock);
    }
    //NSLog(@"%@ buffering ends", self.url);
    isFilling = NO;
    [pool drain];
}

- (id)initWithURL:(NSURL *)anURL
{
    OSStatus err = noErr;
    self = [super init];
    if (self) {
        self.url = anURL;
        UInt32 thePropertySize = sizeof(fileFormat);
        rOffset = wOffset = 0;
        isFilling = NO;
        err = ExtAudioFileOpenURL ( (CFURLRef)anURL, &audioFile );
        if (err != noErr) {
            NSLog(@"Can't open file");
            // TODO - ErrorMessages
        }
        // Get the audio data format
        err = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileDataFormat, &thePropertySize, &fileFormat);
        if (err != noErr) {
            // TODO - ErrorMessages
        } else {
            isFilling = YES;
            [self performSelectorInBackground:@selector(fillBuffer) withObject:nil];
        }
    }
    if (err != noErr) {
        [self dealloc];
        return nil;
    }
    return self;
}

- (void)clearBuffer
{
    for (int i = 0; i < kJMXAudioFileBufferCount; i++) {
        if (samples[i]) {
            [samples[i] release];
            samples[i] = nil;
        }
    }
}

- (void)dealloc
{
    [self clearBuffer];
    if (audioFile)
        ExtAudioFileDispose(audioFile);
    self.url = nil;
    [super dealloc];
}

- (JMXAudioBuffer *)readSample
{
    JMXAudioBuffer *sample = nil;
    OSSpinLockLock(&lock);
    if (rOffset < wOffset || overflow) {
        sample = samples[rOffset%kJMXAudioFileBufferCount];
        samples[rOffset++%kJMXAudioFileBufferCount] = nil;
        if (rOffset == 0 && overflow) // Note: rOffset is always behind wOffset
            overflow = NO;
    }
    if ((wOffset <= rOffset || wOffset - rOffset < kJMXAudioFileBufferCount / 4) && !overflow
        && !isFilling && !(self.currentOffset >= self.numFrames - (512 * self.numChannels)))
    {
        isFilling = YES;
        [self performSelectorInBackground:@selector(fillBuffer) withObject:nil];
    }
    OSSpinLockUnlock(&lock);
    return [sample autorelease];
}

- (JMXAudioBuffer *)readFrames:(NSUInteger)numFrames
{
    UInt32  thePropertySize;
    SInt64  theFileLengthInFrames = 0;
    OSStatus err = noErr;
    AudioStreamBasicDescription		theOutputFormat;
    void *data;
    JMXAudioBuffer *buffer = nil;

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
        NSLog(@"MyGetOpenALAudioData: ExtAudioFileSetProperty(kExtAudioFileProperty_ClientDataFormat) FAILED, Error = %ld\n", (long)err);
        return nil;
    }
	
	// Get the total frame count
	thePropertySize = sizeof(theFileLengthInFrames);
	err = ExtAudioFileGetProperty(audioFile, kExtAudioFileProperty_FileLengthFrames, &thePropertySize, &theFileLengthInFrames);
	if(err) {
        NSLog(@"MyGetOpenALAudioData: ExtAudioFileGetProperty(kExtAudioFileProperty_FileLengthFrames) FAILED, Error = %ld\n", (long)err);
        return nil;
    }
	
	// Read all the data into memory
	//UInt32 theFramesToRead = (UInt32)theFileLengthInFrames;		
	UInt32 dataSize = (UInt32)numFrames * theOutputFormat.mBytesPerFrame;
	data = malloc(dataSize);
	if (data)
	{
        UInt32 nFrames = (UInt32)numFrames;
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
                buffer = [JMXAudioBuffer audioBufferWithCoreAudioBufferList:theDataBuffer 
                                                                  andFormat:(AudioStreamBasicDescription *)&theOutputFormat
                                                                       copy:NO
                                                              freeOnRelease:YES];
            } else {
                free(data);
                free(theDataBuffer);
            }
		}
		else 
		{ 
			// failure
			free (data);
            free(theDataBuffer);
			NSLog(@"MyGetOpenALAudioData: ExtAudioFileRead FAILED, Error = %ld\n", (long)err);
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
