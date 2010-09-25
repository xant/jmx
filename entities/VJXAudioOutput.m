//
//  VJXAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioOutput.h"
#import "VJXAudioBuffer.h"

typedef struct CallbackContext_t {
	VJXAudioBuffer * theConversionBuffer;
	Boolean wait;
    UInt32 offset;
} CallbackContext;

static OSStatus _FillComplexBufferProc (
                                        AudioConverterRef aConveter,
                                        UInt32 * ioNumberDataPackets,
                                        AudioBufferList * ioData,
                                        AudioStreamPacketDescription ** outDataPacketDescription,
                                        void * inUserData
                                        )
{
	CallbackContext * ctx = inUserData;
	
	return [ctx->theConversionBuffer fillComplexBuffer:ioData countPointer:ioNumberDataPackets waitForData:ctx->wait offset:ctx->offset];
}

@implementation VJXAudioOutput
- (id)init
{
    if (self = [super init]) {
        AudioStreamBasicDescription inputDescription;
        AudioStreamBasicDescription outputDescription;
        [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"newSample:"];
        ringBuffer = [[NSMutableArray alloc] init];
        
        if ( noErr != AudioConverterNew ( &inputDescription, &outputDescription, &converter ))
        {
            converter = NULL; // just in case
        }
        
    }
    return self;
}

- (void)newSample:(VJXAudioBuffer *)buffer
{
    @synchronized(ringBuffer) {
        CallbackContext callbackContext;
        AudioBufferList *outputBufferList = calloc(sizeof(AudioBufferList), 1);
        outputBufferList->mNumberBuffers = 1;
        outputBufferList->mBuffers[0].mDataByteSize = 4096;
        outputBufferList->mBuffers[0].mNumberChannels = 2;//[buffer numChannels];
        outputBufferList->mBuffers[0].mData = calloc(4096, 1);
        callbackContext.theConversionBuffer = buffer;
        callbackContext.wait = YES; // XXX
        //UInt32 outputChannels = [buffer numChannels];
        UInt32 framesRead = [buffer numFrames];
        AudioConverterFillComplexBuffer ( converter, _FillComplexBufferProc, &callbackContext, &framesRead, outputBufferList, NULL );
        if (buffer)
            [ringBuffer addObject:buffer];
    }
}

- (VJXAudioBuffer *)currentSample
{
    VJXAudioBuffer *oldestSample = nil;
    @synchronized(ringBuffer) {
        if ([ringBuffer count]) {
            oldestSample = [ringBuffer objectAtIndex:0];
            [ringBuffer removeObjectAtIndex:0];
        }
    }
    return oldestSample;
}

- (void)dealloc
{
    if (ringBuffer)
        [ringBuffer release];
    [super dealloc];
}

@end
