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

@interface JMXEntity (Private)
- (void)run;
@end

@interface JMXThreadedEntity (Private)
- (void)run;
@end

@implementation JMXThreadedEntity

@synthesize frequency, previousTimeStamp, quit, realEntity;

+ (id)threadedEntity:(JMXEntity *)entity
{
    return [[[self alloc] initWithEntity:entity] autorelease];
}

// we need to propagate notifications sent by the object we encapsulate
- (void)hookNotification:(NSNotification *)notification
{
    if (realEntity == [notification object]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:[notification name] 
                                                            object:self 
                                                          userInfo:[notification userInfo]];
    }
}

- (id)initWithEntity:(JMXEntity *)entity
{
    if (entity) {
        worker = nil;
        timer = nil;
        realEntity = [entity retain];
        [realEntity addPrivateData:self forKey:@"threadedEntity"];
        NSBlockOperation *registerObservers = [NSBlockOperation blockOperationWithBlock:^{
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityWasCreated"
                                                       object:realEntity];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityWasDestroyed"
                                                       object:realEntity];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityInputPinAdded"
                                                       object:nil];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityInputPinRemoved"
                                                       object:realEntity];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityOutputPinAdded"
                                                       object:realEntity];
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(hookNotification:)
                                                         name:@"JMXEntityOutputPinRemoved"
                                                       object:realEntity];
        }];
        [registerObservers setQueuePriority:NSOperationQueuePriorityVeryHigh];
        if (![[NSThread currentThread] isMainThread]) {
            [[NSOperationQueue mainQueue] addOperations:[NSArray arrayWithObject:registerObservers]
                                      waitUntilFinished:YES];
        } else {
            [registerObservers start];
            [registerObservers waitUntilFinished];
        }
        // and 'effective' frequency , only for debugging purposes
        self.frequency = [NSNumber numberWithDouble:25.0];
        JMXInputPin *inputFrequency = [entity registerInputPin:@"frequency"
                                                      withType:kJMXNumberPin
                                                   andSelector:@"setFrequency:"];
        [inputFrequency setMinLimit:[NSNumber numberWithFloat:1.0]];
        [inputFrequency setMaxLimit:[NSNumber numberWithFloat:100.0]];
        inputFrequency.data = self.frequency; // set initial value
        frequencyPin = [entity registerOutputPin:@"frequency" withType:kJMXNumberPin];
        stampCount = 0;
        previousTimeStamp = 0;
        quit = NO;
    }
    return self;
}

- (void)dealloc
{
    [self stopThread];
    // TODO - ensure executing the following statement on the main thread
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    //[realEntity removePrivateDataForKey:@"threadedEntity"];
    [realEntity release];
    [super dealloc];
}

- (BOOL)conformsToProtocol:(Protocol *)aProtocol
{
    if ([NSStringFromProtocol(aProtocol) isEqualTo:@"JMXRunLoop"])
        return YES;
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([realEntity respondsToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:realEntity];
    }
}

- (BOOL)respondsToSelector:(SEL)aSelector
{
    return [realEntity respondsToSelector:aSelector];
}

- (void)startThread
{
    if (!worker) {
        NSLog(@"Thread %@ starting", self);
        worker = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [worker setThreadPriority:1.0];
        [worker start];
        quit = NO;
    }
}

- (void)stopThread {
    if (worker) {
        NSLog(@"Thread %@ exiting", self);
        quit = YES;
        [worker cancel];
        // wait for the thread to really finish otherwise it could
        // sill retaining something which is supposed to be released
        // immediately after we return from this method
        //while (![worker isFinished])
          //  [NSThread sleepForTimeInterval:0.1];
        [worker release];
        worker = nil;
    }
}

- (void)tick:(uint64_t)timeStamp
{
    // propagate the tick to the underlying entity
    [realEntity tick:timeStamp];
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
    [realEntity outputDefaultSignals:timeStamp];
}

- (void)signalTick:(NSTimer*)theTimer
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    uint64_t timeStamp = CVGetCurrentHostTime();
    [self tick:timeStamp];
    previousTimeStamp = timeStamp;
    if ([[NSThread currentThread] isCancelled] || quit) {
        [timer invalidate];
        realEntity.active = NO;
    } else {
        [self outputDefaultSignals:timeStamp];
        NSTimeInterval currentInterval = [timer timeInterval];
        NSTimeInterval newInterval = 1.0/[frequency doubleValue];
        if (currentInterval != newInterval) {
            [timer invalidate];
            timer = [NSTimer timerWithTimeInterval:newInterval target:self selector:@selector(signalTick:) userInfo:nil repeats:YES];
            realEntity.active = YES;
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
    realEntity.active = YES;
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    [runLoop run];
    realEntity.active = NO;
    [pool drain];
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

- (void)setActive:(BOOL)value
{
    if (realEntity.active != value) {
        if (value)
            [self start];
        else
            [self stop];
    }
}

- (NSString *)description
{
    return [realEntity description];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [realEntity methodSignatureForSelector:aSelector];
}

@end

#pragma mark JMXEntity (Threaded)

@implementation JMXEntity (Threaded)
- (NSNumber *)frequency
{
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th)
        return th.frequency;
    return nil;
}

- (void)setFrequency:(NSNumber *)frequency
{
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th)
        th.frequency = frequency;
}

- (BOOL)quit
{
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th)
        return th.quit;
    return YES;
}

- (void)setQuit:(BOOL)quit
{
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th)
        th.quit = quit;
}

- (uint64_t)previousTimeStamp
{
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th)
        return th.previousTimeStamp;
    return 0;
}

- (void)tick:(uint64_t)timeStamp
{
    // do nothing
}

- (void)run
{
    // XXX do nothing
}

- (void)start
{
    self.active = YES;
}

- (void)stop
{
    self.active = NO;
}

/*
- (void)setActive:(BOOL)value
{
    if (active != value) {
        active = value;
        JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
        if (th) {
            if (value)
                [th startThread];
            else
                [th stopThread];
        }
    }
}
 */

#pragma mark V8
using namespace v8;

static v8::Handle<Value>Start(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> obj = args.Holder();
    JMXThreadedEntity *entity = (JMXThreadedEntity *)obj->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity start];
    [pool drain];
    return v8::Undefined();
}

static v8::Handle<Value>Stop(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> obj = args.Holder();
    JMXThreadedEntity *entity = (JMXThreadedEntity *)obj->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity stop];
    [pool drain];
    return v8::Undefined();
}


+ (void)jsObjectTemplateAddons:(v8::Handle<v8::FunctionTemplate>)objectTemplate;
{
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(Start));
    classProto->Set("stop", FunctionTemplate::New(Stop));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    NSLog(@"Installed accessors for 'Threaded' entities");
}

@end