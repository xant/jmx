//
//  VJXAudioOutput.m
//  VeeJay
//
//  Created by xant on 9/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioOutput.h"
#import "VJXAudioBuffer.h"

@implementation VJXAudioOutput
- (id)init
{
    if (self = [super init]) {
        [self registerInputPin:@"audio" withType:kVJXAudioPin andSelector:@"playAudio:"];
    }
    return self;
}

- (void)playAudio:(VJXAudioBuffer *)buffer
{
    @synchronized(self) {
        if (currentSample)
            [currentSample release];
        currentSample = [buffer retain];
    }
}

- (void)dealloc
{
    if (currentSample)
        [currentSample release];
    [super dealloc];
}

@end
