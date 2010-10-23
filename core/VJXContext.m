//
//  VJXContext.m
//  VeeJay
//
//  Created by xant on 9/2/10.
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

#import "VJXContext.h"
#import "VJXEntity.h"

#if !USE_NSOPERATIONS
#define kVJXContextSignalNumWorkers 6
static NSThread *signalThread[kVJXContextSignalNumWorkers];
#endif
static VJXContext *globalContext = nil;
static BOOL initialized = NO;

@interface VJXContext (Private)
- (void)runThread;
@end

@implementation VJXContext

+ (void)initialize
{
    if (!initialized) {
        if (!globalContext)
            globalContext = [[VJXContext alloc] init];
#if !USE_NSOPERATIONS
        for (int i = 0; i < kVJXContextSignalNumWorkers; i++) {
            if (!signalThread[i]) {
                signalThread[i] = [[NSThread alloc] initWithTarget:globalContext selector:@selector(runThread) object:nil];
                [signalThread[i] setName:[NSString stringWithFormat:@"signalThread%d", i]]; 
                [signalThread[i] start];
            }
        }
#endif
        initialized = YES;
    }
}

#if !USE_NSOPERATIONS
+ (NSThread *)signalThread
{
    static unsigned int sel = 0;
    return signalThread[++sel%kVJXContextSignalNumWorkers];
}
#else
+ (NSOperationQueue *)operationQueue
{
    if (globalContext)
        return globalContext.operationQueue;
    return nil;
}
- (void)initQueue
{
    operationQueue = [[NSOperationQueue alloc] init];
    [operationQueue setMaxConcurrentOperationCount:4];
}
#endif

+ (VJXContext *)sharedContext
{
	return globalContext;
}

- (id)init
{
    self = [super init];
	if (self) {
        entities = [[NSMutableDictionary alloc] init];
		registeredClasses = [[NSMutableArray alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasCreated:) name:@"VJXEntityWasCreated" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasDestroyed:) name:@"VJXEntityWasDestroyed" object:nil];
#if USE_NSOPERATIONS
        [self initQueue];
#endif
	}
	return self;
}

- (void)dealloc
{
	[registeredClasses release];
#if USE_NSOPERATIONS
    [operationQueue release];
#endif
	[super dealloc];
}

- (void)anEntityWasCreated:(NSNotification *)notification
{
    VJXEntity *entity = [notification object];
    @synchronized(self) {
        NSValue *value = [NSValue valueWithNonretainedObject:entity];
        [entities setObject:value forKey:[NSString stringWithFormat:@"%d", entity]];
    }
}

- (void)anEntityWasDestroyed:(NSNotification *)notification
{
    VJXEntity *entity = [notification object];
    @synchronized(self) {
        [entities removeObjectForKey:[NSString stringWithFormat:@"%d", entity]];
    }
}

- (NSArray *)allEntities
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    @synchronized(self) {
        for (NSValue *entityValue in [entities allValues]) {
            [array addObject:(VJXEntity *)[entityValue pointerValue]];
        }
    }
    return [array autorelease];
}

- (void)runThread
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    
    int running = true;
    [[NSRunLoop currentRunLoop] addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
    while (running && [runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]){
        //run loop spinned ones
    }
    //[runLoop run];
    [pool drain];
}

- (void)registerClass:(Class)aClass
{
	[registeredClasses addObject:aClass];
}

- (NSArray *)registeredClasses
{
	return (NSArray *)registeredClasses;
}

#if USE_NSOPERATIONS
@synthesize operationQueue;
#endif

@end
