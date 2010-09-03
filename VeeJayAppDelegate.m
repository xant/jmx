//
//  VeeJayAppDelegate.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VeeJayAppDelegate.h"
#import "VJXOpenGLScreen.h"
#import "VJXMixer.h"

@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSize blah = { 320, 240 };
    VJXMixer *mixer = [[VJXMixer alloc] init];
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] initWithSize:blah];
    [mixer start];
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}

@end
