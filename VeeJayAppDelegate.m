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
#import "VJXMovieLayer.h"

@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSSize blah = { 640, 480 };
    /* TEST CODE */
    VJXMixer *mixer = [[VJXMixer alloc] init];
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] initWithSize:blah];
    VJXImageLayer *imageLayer = [[VJXImageLayer alloc] init];
    VJXMovieLayer *movieLayer = [[VJXMovieLayer alloc] init];
    movieLayer.moviePath = @"/Users/xant/test.avi";
    [movieLayer loadMovie];
    VJXPin *moviePin = [movieLayer outputPinWithName:@"outputFrame"];
    VJXPin *imagePin = [imageLayer outputPinWithName:@"outputFrame"];
    VJXPin *mixerPin = [mixer inputPinWithName:@"videoInput"];
    VJXPin *mixerOut = [mixer outputPinWithName:@"videoOutput"];
    VJXPin *screenInput = [screen inputPinWithName:@"inputFrame"];
    [mixerPin connectToPin:imagePin];
    [mixerPin connectToPin:moviePin];
    [screenInput connectToPin:mixerOut];
    NSLog(@"%@\n", [mixerPin name]);
    //NSLog(@"%@\n", mixerPin);
    [imageLayer start];
    [movieLayer start];
    [mixer start];
    /* END OF TEST CODE */
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}

@end
