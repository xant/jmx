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
    /* TEST CODE */
    // CREATE A MIXER
    VJXMixer *mixer = [[VJXMixer alloc] init];
    
    // CREATE A SCREEN
    NSSize screenSize = { 640, 480 };
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] initWithSize:screenSize];
    
    // CREATE LAYERS (producing frames)
    VJXImageLayer *imageLayer = [[VJXImageLayer alloc] init];
    VJXMovieLayer *movieLayer = [[VJXMovieLayer alloc] init];
    movieLayer.moviePath = @"/Users/xant/test.avi";
    [movieLayer loadMovie];
    
    // GET ALL PINS WE WANT TO CONNECT ONE TO EACH OTHER
    VJXPin *moviePin = [movieLayer outputPinWithName:@"outputFrame"];
    VJXPin *imagePin = [imageLayer outputPinWithName:@"outputFrame"];
    VJXPin *mixerPin = [mixer inputPinWithName:@"videoInput"];
    VJXPin *mixerOut = [mixer outputPinWithName:@"videoOutput"];
    VJXPin *screenInput = [screen inputPinWithName:@"inputFrame"];
    
    // CONNECT PINS AS NECESSARY :
    // FIRST THE LAYERS TO THE MIXER
    [mixerPin connectToPin:imagePin];
    [mixerPin connectToPin:moviePin];
    // AND THEN THE MIXER TO THE SCREEN
    [screenInput connectToPin:mixerOut];

    // START EVERYTHING
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
