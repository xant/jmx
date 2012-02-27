//
//  JMXContext.m
//  JMX
//
//  Created by xant on 9/2/10.
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

#import "JMXContext.h"
#import "JMXEntity.h"
#import "JMXGraph.h"
#import "JMXAttribute.h"

#define kJMXContextSignalNumWorkers 6

#if !USE_NSOPERATIONS
static NSThread *signalThread[kJMXContextSignalNumWorkers];
#endif
static JMXContext *globalContext = nil;
static BOOL initialized = NO;

@interface JMXContext (Private)
- (void)runThread;
@end

@implementation JMXContext

@synthesize dom;

+ (void)initialize
{
    if (!initialized) {
        if (!globalContext)
            globalContext = [[JMXContext alloc] init];
#if !USE_NSOPERATIONS
        for (int i = 0; i < kJMXContextSignalNumWorkers; i++) {
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
    return signalThread[++sel%kJMXContextSignalNumWorkers];
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
    [operationQueue setMaxConcurrentOperationCount:kJMXContextSignalNumWorkers];
}
#endif

+ (JMXContext *)sharedContext
{
	return globalContext;
}

#import "JMXHIDDevice.h"

- (id)init
{
    self = [super init];
	if (self) {
        entities = [[NSMutableDictionary alloc] init];
		registeredClasses = [[NSMutableArray alloc] init];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasCreated:) name:@"JMXEntityWasCreated" object:nil];
        //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasDestroyed:) name:@"JMXEntityWasDestroyed" object:nil];
        NSXMLElement *root = [[[JMXElement alloc] initWithName:@"JMX"] autorelease];
        [root addAttribute:[JMXAttribute attributeWithName:@"label"
                                               stringValue:@"jmx"]];
        
        dom = [[JMXGraph alloc] initWithRootElement:root];
        [dom setName:@"JMXGraph"];
        NSXMLNode *ns = [[[NSXMLNode alloc] initWithKind:NSXMLNamespaceKind] autorelease];
        [ns setStringValue:@"http://jmxapp.org"];
        [ns setName:@"jmx"];
        [root addNamespace:ns];
#if USE_NSOPERATIONS
        [self initQueue];
#endif
	}
	return self;
}

- (void)dealloc
{
	[registeredClasses release];
    [dom release];
#if USE_NSOPERATIONS
    [operationQueue release];
#endif
	[super dealloc];
}

- (void)anEntityWasCreated:(NSNotification *)notification
{
    JMXEntity *entity = [notification object];
    [self addEntity:entity];
}

- (void)anEntityWasDestroyed:(NSNotification *)notification
{
    JMXEntity *entity = [notification object];
    [self removeEntity:entity];
}

- (void)addEntity:(JMXEntity *)entity
{
    @synchronized(self) {
        if (!entity.parent && ![entity isProxy]) {
            NSValue *value = [NSValue valueWithNonretainedObject:entity];
            [entities setObject:value forKey:[NSString stringWithFormat:@"%d", entity]];
        }
    }
}

- (void)removeEntity:(JMXEntity *)entity
{
    @synchronized(self) {
        if (entity.parent && ![entity isProxy]) {
            [entities removeObjectForKey:[NSString stringWithFormat:@"%d", entity]];
        }
    }
}

- (NSArray *)allEntities
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    @synchronized(self) {
        for (NSValue *entityValue in [entities allValues]) {
            [array addObject:(JMXEntity *)[entityValue pointerValue]];
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

- (NSString *)dumpDOM
{
    return [dom XMLStringWithOptions:NSXMLNodePrettyPrint|NSXMLNodeCompactEmptyElement];
}

#if USE_NSOPERATIONS
@synthesize operationQueue;
#endif

@end
