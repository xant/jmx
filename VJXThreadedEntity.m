//
//  VJXEntity+Threaded.m
//  VeeJay
//
//  Created by xant on 9/7/10.
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

#import "VJXThreadedEntity.h"
#import <QuartzCore/QuartzCore.h>

@implementation VJXThreadedEntity

@synthesize frequency;

- (id)init
{
    if (self == [super init]) {
        worker = nil;
        timer = nil;
        // and 'effective' frequency , only for debugging purposes
        self.frequency = [NSNumber numberWithDouble:25.0];
        [self registerInputPin:@"frequency" withType:kVJXNumberPin andSelector:@"setFrequency:"];
        [self registerInputPin:@"active" withType:kVJXNumberPin andSelector:@"setActive:"];
        [self registerOutputPin:@"outputFrequency" withType:kVJXNumberPin];
        stampCount = 0;
        previousTimeStamp = 0;
    }
    return self;
}

- (void)dealloc
{
    [self stop];
    [super dealloc];
}

- (void)start
{
    if (!worker) {
        worker = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [worker start];
        [worker release];
    }
}

- (void)stop {
    if (worker) {
        [timer invalidate];
        [worker cancel];
        while (![worker isFinished])
            [NSThread sleepForTimeInterval:0.001];
        worker = nil;
    }
}

- (void)tick:(uint64_t)timeStamp
{
    // do nothing (for now)
}

- (void)signalTick:(NSTimer*)theTimer
{
    uint64_t timeStamp = CVGetCurrentHostTime();
    [self tick:timeStamp];
    [self outputDefaultSignals:timeStamp];
}

- (void)run
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    double maxDelta = 1.0/[frequency doubleValue];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:maxDelta target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
    active = YES;
    [[NSRunLoop currentRunLoop] run];
    [pool drain];
    active = NO;
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    VJXPin *frequencyPin = [self outputPinWithName:@"outputFrequency"];
    int i = 0;
    if (stampCount > kVJXFpsMaxStamps) {
        for (i = 0; i < stampCount; i++) {
            stamps[i] = stamps[i+1];
        }
        stampCount = kVJXFpsMaxStamps;  
    }
    stamps[stampCount++] = timeStamp;
    
    double rate = 1e9/((stamps[stampCount - 1] - stamps[0])/stampCount);
    [frequencyPin deliverSignal:[NSNumber numberWithDouble:rate]
                     fromSender:self];
    //NSLog(@"%@\n", [NSNumber numberWithDouble:rate]);
    [super outputDefaultSignals:timeStamp];
}

@end
