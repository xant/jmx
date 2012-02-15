//
//  JMXScriptLive.m
//  JMX
//
//  Created by xant on 12/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptLive.h"


@implementation JMXScriptLive

- (id)init
{
    self = [super init];
    if (self) {
        codeInputPin = [self registerInputPin:@"code" withType:kJMXCodePin andSelector:@"execCode:"];
        codeOutputPin = [self registerOutputPin:@"runningCode" withType:kJMXCodePin andSelector:@"executedCode:"];
        history = [[NSString alloc] init];
    }
    return self;
}

- (void)execCode:(NSString *)jsCode
{
    self.code = jsCode;
    if ([self exec]) {
        NSString *newHistory = [NSString stringWithFormat:@"%@\n%@", history, jsCode];
        [history release];
        history = [newHistory retain];
        codeOutputPin.data = history;
    } else {
        // TODO - show an alert to the user
    }
}

- (void)dealloc
{
    [history release];
    [super dealloc];
}

@end
