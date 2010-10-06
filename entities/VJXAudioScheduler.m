//
//  VJXAudioScheduler.m
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXAudioScheduler.h"
#import "VJXAudioFileLayer.h"

@implementation VJXAudioScheduler

- (id)init
{
    if (self = [super init]) {
        currentIndex = 0;
        started = NO;
    }
    return self;
}

- (void)tick:(uint64_t)timeStamp
{
    //[startPin deliverSignal:[NSNumber numberWithInt:0]];
    NSArray *producers  = audioInputPin.producers;
    if (producers && [producers count]) {
        for (int i = 0; i < [producers count]; i++) {
            VJXPin *producer = [producers objectAtIndex:i];
            VJXAudioFileLayer *audioFile = producer.owner;//[producer readPinValue];
            if (!audioFile)
                continue;
            audioFile.repeat = NO; // ensure keeping repeat set to NO
            if (i == currentIndex) {
                if (started) {
                    if (!audioFile.active) {
                        currentIndex++;
                        [((VJXPin *)[producers objectAtIndex:currentIndex%[producers count]]).owner activate];
                        continue;
                    }
                } else {
                    started = YES;
                    [audioFile activate];
                }
            } else {
                [audioFile deactivate];
            }
        }
    }
    [super tick:timeStamp]; // let the mixer do its job
}

@end
