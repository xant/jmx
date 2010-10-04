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
        startPin = [self registerOutputPin:@"start" withType:kVJXNumberPin];
        stopPin = [self registerOutputPin:@"stop" withType:kVJXNumberPin];
        currentIndex = 0;
        started = NO;
    }
    return self;
}

- (void)tick:(uint64_t)timeStamp
{
    //[startPin deliverSignal:[NSNumber numberWithInt:0]];
    NSArray *receivers  = [startPin.receivers allKeys];
    if (receivers && [receivers count]) {
        VJXAudioFileLayer *audioFile = [[receivers objectAtIndex:currentIndex] owner];
        if (started) {
            if (audioFile && !audioFile.active) {
                currentIndex++;
                [audioFile activate];
            }
        } else {
            [[[receivers objectAtIndex:currentIndex] owner] activate];
            //NSLog(@"%@", [receivers objectAtIndex:0]);
        }
        for (VJXPin *receiver in receivers) {
            if (receiver.owner != audioFile)
                [receiver.owner deactivate];
        }
    }
    [stopPin deliverSignal:[NSNumber numberWithInt:0]];
    [super tick:timeStamp];
}

@end
