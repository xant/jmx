//
//  JMXScriptLive.m
//  JMX
//
//  Created by xant on 12/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptLive.h"
#import "JMXThreadedEntity.h"
#import "JMXScript.h"

@implementation JMXScriptLive
@synthesize scriptThread;

- (id)initWithName:(NSString *)name
{
    self = [super initWithName:name];
    if (self) {
        codeInputPin = [self registerInputPin:@"code" withType:kJMXCodePin andSelector:@"execCode:"];
        JMXThreadedEntity *threadedEntity = [[JMXThreadedEntity threadedEntity:self] retain];
        if (threadedEntity) {
            scriptThread = threadedEntity.worker;
            return (JMXScriptLive *)threadedEntity;
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.label = @"JMXScriptLive";
        codeInputPin = [self registerInputPin:@"code" withType:kJMXCodePin andSelector:@"execCode:"];
        JMXThreadedEntity *threadedEntity = [[JMXThreadedEntity threadedEntity:self] retain];
        if (threadedEntity) {
            scriptThread = threadedEntity.worker;
            return (JMXScriptLive *)threadedEntity;
        } else {
            [self release];
            return nil;
        }
    }
    return self;
}

- (void)execCodeInternal:(NSString *)jsCode
{
    @synchronized(self) {
        if ([self exec:jsCode]) {
            NSString *history = [NSString stringWithFormat:@"%@\n%@", self.code, jsCode];
            self.code = history;
        } else {
            // TODO - show an alert to the user
        }
    }
}

- (void)execCode:(NSString *)jsCode
{
    [self performSelector:@selector(execCodeInternal:)
                             onThread:[self scriptThread]
                           withObject:jsCode
                        waitUntilDone:YES
                                modes:nil];
}

- (void)dealloc
{
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
//    @synchronized(self) {
//        if (jsContext)
//            [jsContext nodejsRun];
//    }
    [super tick:timeStamp];
}

@end
