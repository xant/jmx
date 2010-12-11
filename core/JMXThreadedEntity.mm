//
//  JMXEntity+Threaded.m
//  JMX
//
//  Created by xant on 9/7/10.
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

#import <QuartzCore/QuartzCore.h>
#define __JMXV8__ 1
#import "JMXThreadedEntity.h"
#import "JMXScript.h"

@interface JMXThreadedEntity (Private)
- (void)run;
@end

@implementation JMXThreadedEntity

@synthesize frequency;

- (id)init
{
    self = [super init];
    if (self) {
        worker = nil;
        timer = nil;
        // and 'effective' frequency , only for debugging purposes
        self.frequency = [NSNumber numberWithDouble:25.0];
        JMXInputPin *inputFrequency =[self registerInputPin:@"frequency" withType:kJMXNumberPin andSelector:@"setFrequency:"];
        [inputFrequency setMinLimit:[NSNumber numberWithFloat:1.0]];
        [inputFrequency setMaxLimit:[NSNumber numberWithFloat:60.0]];
        frequencyPin = [self registerOutputPin:@"frequency" withType:kJMXNumberPin];
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
    if (worker) {
        active = NO;
        quit = YES;
        [worker cancel];
        // wait for the thread to really finish otherwise it could
        // sill retaining something which is supposed to be released
        // immediately after we return from this method
        //while (![worker isFinished])
            //[NSThread sleepForTimeInterval:0.001];
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
        NSLog(@"Thread %@ exiting", self);
        [timer invalidate];
        active = NO;
    } else {
        [self outputDefaultSignals:timeStamp];
        NSTimeInterval currentInterval = [timer timeInterval];
        NSTimeInterval newInterval = 1.0/[frequency doubleValue];
        if (currentInterval != newInterval) {
            [timer invalidate];
            timer = [NSTimer timerWithTimeInterval:newInterval target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
            active = YES;
            NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
            [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
        }
    }
    [pool release];
}

- (void)run
{
#if 1
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    double maxDelta = 1.0/[self.frequency doubleValue];
    timer = [NSTimer timerWithTimeInterval:maxDelta target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
    active = YES;
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    [runLoop run];
    [pool drain];
    active = NO;
#else
    uint64_t maxDelta = 1e9 / [frequency doubleValue];
    
    NSThread *currentThread = [NSThread currentThread];
    
    active = YES;
    while (![currentThread isCancelled]) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        uint64_t timeStamp = CVGetCurrentHostTime();
        if ([self respondsToSelector:@selector(tick:)])
            [self tick:timeStamp];
        [self outputDefaultSignals:timeStamp]; // ensure sending all default signals
        previousTimeStamp = timeStamp;
        uint64_t now = CVGetCurrentHostTime();
        // Check if tick() has returned earlier and we still have time before next tick. 
        // If the current delta is smaller than our frequency, we will wait the difference
        // between maxDelta and delta to honor the configured frequency.
        // Otherwise, since we would be already late, we just skip the sleep time and 
        // go for the next frame.
        uint64_t delta = now - timeStamp;
        uint64_t sleepTime = (delta && delta < maxDelta) ? maxDelta - delta : 0;
        
        if (sleepTime) {
#if 1
            // using nanosleep is a good portable way, but since we are running 
            // on OSX only, we should try relying on the NSThread API.
            // We will switch back to nanosleep if we notice that 'sleepForTimeInterval'
            // is not precise enough.
            struct timespec time = { 0, 0 };
            struct timespec remainder = { 0, sleepTime };
            do {
                time.tv_sec = remainder.tv_sec;
                time.tv_nsec = remainder.tv_nsec;
                remainder.tv_nsec = 0;
                nanosleep(&time, &remainder);
            } while (remainder.tv_sec || remainder.tv_nsec);
#else
            // let's try if NSThread facilities are reliable (in terms of time precision)
            do {
                [NSThread sleepForTimeInterval:0.001];
            } while (CVGetCurrentHostTime() - timeStamp <= sleepTime); // we need to be as precise as possible
#endif
        } else {
            // mmm ... no sleep time ... perhaps we are out of resources and slowing down mixing
            // TODO - produce a warning in this case
        }
        [pool drain];
    }
    active = NO;
#endif
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    int i = 0;
    if (stampCount > kJMXFpsMaxStamps) {
        for (i = 0; i < stampCount; i++) {
            stamps[i] = stamps[i+1];
        }
        stampCount = kJMXFpsMaxStamps;  
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
    JMXThreadedEntity *entity = (JMXThreadedEntity *)self->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity start];
    [pool drain];
    return v8::Undefined();
}

static v8::Handle<Value> stop(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    JMXThreadedEntity *entity = (JMXThreadedEntity *)self->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity stop];
    [pool drain];
    return v8::Undefined();
}

static Persistent<FunctionTemplate> classTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXThreadedEntity ClassTemplate created");
    classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);
    classTemplate->SetClassName(String::New("ThreadedEntity"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(start));
    classProto->Set("stop", FunctionTemplate::New(stop));
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    return classTemplate;
}

@end
