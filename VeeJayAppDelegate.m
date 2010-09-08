//
//  VeeJayAppDelegate.m
//  VJX
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VeeJayAppDelegate.h"

// HERE FOR TESTING
#import "VJXOpenGLScreen.h"
#import "VJXMixer.h"
#import "VJXImageLayer.h"
#import "VJXQtVideoLayer.h"
#import "VJXPoint.h"
// END OF HERE FOR TESTING
@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)printFrequency:(id)data andSender:(id)sender
{
    NSLog(@"Frequency for %@: %@\n", sender, data); 
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}


- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

@end
