//
//  VJXThread.m
//  VeeJay
//
//  Created by xant on 9/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntity+Thread.h"
#import <QuartzCore/QuartzCore.h>

static NSMutableDictionary *workers = NULL;

@implementation VJXEntity (Threaded)

- (void)start
{
    if (!workers)
        workers = [[NSMutableDictionary alloc] init]; // initialize on first use
    if (![workers objectForKey:self]) {
        NSThread *newThread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [workers setObject:newThread
                    forKey:self];
        [newThread start];
    }
}

- (void)stop {
    NSThread *thread;
    if (thread = [workers objectForKey:self]) {
        [workers removeObjectForKey:self];
        [thread cancel];
    }
}

- (void)run
{
    uint64_t maxDelta = 1e9 / _fps;
    
    NSThread *currentThread = [NSThread currentThread];
    
    while (![currentThread isCancelled]) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        uint64_t timeStamp = CVGetCurrentHostTime();
        // Calculate delta of current and last time. If the current delta is
        // smaller than the maxDelta for 24fps, we wait the difference between
        // maxDelta and delta. Otherwise we just skip the sleep time and go for
        // the next frame.
        uint64_t delta = previousTimeStamp ? timeStamp - previousTimeStamp : 0;
        uint64_t sleepTime = delta < maxDelta ? maxDelta - delta : 0;
        
        if (sleepTime > 0) {
            // NSLog(@"Will wait %llu nanoseconds", sleepTime);
            struct timespec time = { 0, 0 };
            struct timespec remainder = { 0, sleepTime };
            do {
                //time.tv_sec = remainder.tv_sec;
                time.tv_nsec = remainder.tv_nsec;
                remainder.tv_nsec = 0;
                nanosleep(&time, &remainder);
            } while (remainder.tv_sec || time.tv_nsec);
        } else {
            // mmm ... no sleep time ... perhaps we are out of resources and slowing down mixing
            // TODO - produce a warning in this case
        }
        [self tick:timeStamp];
        previousTimeStamp = timeStamp;
        [pool drain];
    }
}

- (void)dealloc
{
    [self stop];
    [inputPins release];
    [outputPins release];
    [super dealloc];
}

@end
