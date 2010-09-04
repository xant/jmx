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
#import "VJXImageLayer.h"

@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSize blah = { 320, 240 };
    VJXMixer *mixer = [[VJXMixer alloc] init];
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] initWithSize:blah];
    VJXImageLayer *imageLayer = [[VJXImageLayer alloc] init];
    VJXPin *imagePin = [imageLayer outputPinWithName:@"outputFrame"];
    VJXPin *mixerPin = [mixer inputPinWithName:@"videoInput"];
    VJXPin *mixerOut = [mixer outputPinWithName:@"videoOutput"];
    VJXPin *screenInput = [screen inputPinWithName:@"inputFrame"];
    [mixerPin connectToPin:imagePin];
    [screenInput connectToPin:mixerOut];
    NSLog(@"%@\n", mixerPin);
    [imageLayer start];
    [mixer start];
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}

@end
