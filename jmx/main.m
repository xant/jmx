//
//  main.m
//  jmx
//
//  Created by Andrea Guzzo on 9/25/13.
//  Copyright (c) 2013 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JMXGlobals.h>
#import <JMXApplication.h>
#import <JMXScriptEntity.h>
#import <JMXContext.h>
#import <JMXGraph.h>

static JMXScriptEntity *scriptController = nil;

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        JMXApplication *app =[[JMXApplication alloc] init];
        [NSApplication sharedApplication].delegate = app;
        openlog("JMX", LOG_PERROR, LOG_USER);
        [app applicationWillFinishLaunching:[NSNotification notificationWithName:@"applicationWillFinishLaunching" object:nil]];
        [app applicationDidFinishLaunching:[NSNotification notificationWithName:@"applicationDidFinishLaunching" object:nil]];
        scriptController = [[JMXScriptEntity alloc] initWithName:@"scriptController"];
        NSXMLElement *rootElement = [[[JMXContext sharedContext] dom] rootElement];
        @synchronized(rootElement) {
            [rootElement addChild:scriptController];
        }
        scriptController.active = YES;
        [scriptController exec:@"echo('CIAO');"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop run];
    }
    return 0;
}

