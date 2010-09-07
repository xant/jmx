//
//  MoviePlayerDAppDelegate.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#if MAC_OS_X_VERSION_10_6
@interface VeeJayAppDelegate : NSObject <NSApplicationDelegate> {
#else
@interface VeeJayAppDelegate : NSObject {
#endif
    NSWindow *window;
    NSTableView *layersTableView;
}

@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSTableView *layersTableView;

@end
