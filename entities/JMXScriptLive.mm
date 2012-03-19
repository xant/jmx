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

- (id)init
{
    self = [super init];
    if (self) {
        self.label = @"JMXScriptLive";
        codeInputPin = [self registerInputPin:@"code" withType:kJMXCodePin andSelector:@"execCode:"];
        JMXThreadedEntity *threadedEntity = [[JMXThreadedEntity threadedEntity:self] retain];
        if (threadedEntity)
            return (JMXScriptLive *)threadedEntity;
    }
    return self;
}

- (void)execCode:(NSString *)jsCode
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

- (void)dealloc
{
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (jsContext)
            [jsContext nodejsRun];
    }
    [super tick:timeStamp];
}

@end
