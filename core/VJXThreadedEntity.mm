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

#import <QuartzCore/QuartzCore.h>
#define __VJXV8__ 1
#import "VJXThreadedEntity.h"
#import "VJXJavaScript.h"

@interface VJXThreadedEntity (Private)
- (void)run;
@end

@implementation VJXThreadedEntity

@synthesize frequency;

- (id)init
{
    self = [super init];
    if (self) {
        worker = nil;
        timer = nil;
        // and 'effective' frequency , only for debugging purposes
        self.frequency = [NSNumber numberWithDouble:25.0];
        [self registerInputPin:@"frequency" withType:kVJXNumberPin andSelector:@"setFrequency:"];
        frequencyPin = [self registerOutputPin:@"frequency" withType:kVJXNumberPin];
        stampCount = 0;
        previousTimeStamp = 0;
        quit = NO;
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
    if (worker) {
        [self stop];
        [worker release];
    }
    worker = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
    [worker setThreadPriority:1.0];
    [worker start];
    active = YES;
    quit = NO;
}

- (void)stop {
    if (worker && ![worker isFinished]) {
        active = NO;
        [worker cancel];
        // wait for the thread to really finish otherwise it could
        // sill retaining something which is supposed to be released
        // immediately after we return from this method
        //while (![worker isFinished])
        //    [NSThread sleepForTimeInterval:0.001];
        [worker autorelease];
        worker = nil;
    }
}

- (void)tick:(uint64_t)timeStamp
{
    // do nothing (for now)
}

- (void)signalTick:(NSTimer*)theTimer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    uint64_t timeStamp = CVGetCurrentHostTime();
    [self tick:timeStamp];
    if ([[NSThread currentThread] isCancelled] || quit) {
        [timer invalidate];
        active = NO;
    } else {
        [self outputDefaultSignals:timeStamp];
        /*
        NSTimeInterval currentInterval = [timer timeInterval];
        NSTimeInterval newInterval = 1.0/[frequency doubleValue];
        if (currentInterval != newInterval) {
            [timer invalidate];
            [timer release];
            timer = [NSTimer timerWithTimeInterval:newInterval target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
            active = YES;
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
        }
         */
    }
    [pool release];
}

- (void)run
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    double maxDelta = 1.0/[self.frequency doubleValue];
    timer = [NSTimer timerWithTimeInterval:maxDelta target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
    active = YES;
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    [runLoop run];
    [pool drain];
    active = NO;
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    int i = 0;
    if (stampCount > kVJXFpsMaxStamps) {
        for (i = 0; i < stampCount; i++) {
            stamps[i] = stamps[i+1];
        }
        stampCount = kVJXFpsMaxStamps;  
    }
    stamps[stampCount++] = timeStamp;
    
    double rate = 1e9/((stamps[stampCount - 1] - stamps[0])/stampCount);
    [frequencyPin deliverData:[NSNumber numberWithDouble:rate]
                     fromSender:self];
    //NSLog(@"%@\n", [NSNumber numberWithDouble:rate]);
    [super outputDefaultSignals:timeStamp];
}

- (void)setActive:(BOOL)value
{
    if (active != value) {
        if (value)
            [self start];
        else
            [self stop];
    }
}

#pragma mark V8
using namespace v8;

static v8::Handle<Value> start(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    VJXThreadedEntity *entity = (VJXThreadedEntity*)wrap->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity start];
    [pool drain];
    return v8::Undefined();
}

static v8::Handle<Value> stop(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    VJXThreadedEntity *entity = (VJXThreadedEntity*)wrap->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity stop];
    [pool drain];
    return v8::Undefined();
}

+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    v8::Handle<v8::FunctionTemplate> entityTemplate = [super jsClassTemplate];
    entityTemplate->SetClassName(String::New("ThreadedEntity"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(start));
    classProto->Set("stop", FunctionTemplate::New(stop));
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    return handleScope.Close(entityTemplate);
}

@end
