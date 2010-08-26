//
//  VeeJayAppDelegate.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VeeJayAppDelegate.h"

@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}

@end
