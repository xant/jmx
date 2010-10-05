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
        self.frequency = [NSNumber numberWithDouble:1]; // 1 tick per second
        startPin = [self registerInputPin:@"entity" withType:kVJXEntityPin];
        [startPin allowMultipleConnections:YES];
        currentIndex = 0;
        started = NO;
    }
    return self;
}

- (void)tick:(uint64_t)timeStamp
{
    //[startPin deliverSignal:[NSNumber numberWithInt:0]];
    NSArray *producers  = startPin.producers;
    if (producers && [producers count]) {
        for (int i = 0; i < [producers count]; i++) {
            VJXPin *producer = [producers objectAtIndex:i];
            VJXAudioFileLayer *audioFile = [producer readPinValue];
            if (!audioFile)
                continue;
            audioFile.repeat = NO; // ensure keeping repeat set to NO
            if (i == currentIndex) {
                if (started) {
                    if (!audioFile.active) {
                        currentIndex++;
                        [[[producers objectAtIndex:currentIndex%[producers count]] readPinValue] activate];
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
    [super tick:timeStamp];
}

@end
