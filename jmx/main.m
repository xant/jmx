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

#
static JMXScriptEntity *scriptController = nil;

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        JMXApplication *app =[[JMXApplication alloc] init];
        app.appName = @"jmx-cli";
        [NSApplication sharedApplication];

        [NSApp setDelegate:app];
        openlog(app.appName.UTF8String, LOG_PERROR, LOG_USER);

        scriptController = [[JMXScriptEntity alloc] init];
        scriptController.name = @"scriptController";
        NSXMLElement *rootElement = [[[JMXContext sharedContext] dom] rootElement];
        @synchronized(rootElement) {
            [rootElement addChild:scriptController];
        }
        scriptController.active = YES;
        [scriptController exec:@""];
        
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        
        NSMenu *menubar = [NSMenu new];
        NSMenuItem *appMenuItem = [NSMenuItem new];
        
        [menubar addItem:appMenuItem];
        [NSApp setMainMenu:menubar];
        
        NSMenu *appMenu = [NSMenu new];
        
        NSString *quitTitle = [@"Quit " stringByAppendingString:app.appName];
        NSMenuItem *quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                                     action:@selector(terminate:) keyEquivalent:@"q"];
        [appMenu addItem:quitMenuItem];
        [appMenuItem setSubmenu:appMenu];
        
        NSWindow *window = [[NSWindow alloc] initWithContentRect:NSZeroRect
                                                       styleMask:NSTitledWindowMask
                                                         backing:NSBackingStoreBuffered defer:NO];
        //[window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        window.title = app.appName;
        window.isVisible = NO;
        [window makeKeyAndOrderFront:nil];
//        [NSApp activateIgnoringOtherApps:YES];
        
        [NSApp run];
    }
    return 0;
}

