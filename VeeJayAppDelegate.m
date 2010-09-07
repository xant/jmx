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
    return;
    /* TEST CODE */
    // CREATE A MIXER
    VJXMixer *mixer = [[VJXMixer alloc] init];
    
    // CREATE A SCREEN
    NSSize screenSize = { 640, 480 };
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] initWithSize:screenSize];
    VJXOpenGLScreen *screen2 = [[VJXOpenGLScreen alloc] initWithSize:screenSize];
    NSPoint makeItVisible = { 500, 500 };
    [screen2.window setFrameOrigin:makeItVisible];
    
    // CREATE LAYERS (producing frames)
    VJXImageLayer *imageLayer = [[VJXImageLayer alloc] init];
    VJXQtVideoLayer *movieLayer = [[VJXQtVideoLayer alloc] init];
    movieLayer.moviePath = [@"~/test.avi" stringByExpandingTildeInPath];
    [movieLayer loadMovie];
    
    // GET ALL PINS WE WANT TO CONNECT ONE TO EACH OTHER
    VJXPin *moviePin = [movieLayer outputPinWithName:@"outputFrame"];
    VJXPin *imagePin = [imageLayer outputPinWithName:@"outputFrame"];
    VJXPin *mixerPin = [mixer inputPinWithName:@"videoInput"];
    VJXPin *mixerOut = [mixer outputPinWithName:@"videoOutput"];
    VJXPin *screenInput = [screen inputPinWithName:@"inputFrame"];
    VJXPin *screenInput2 = [screen2 inputPinWithName:@"inputFrame"];

    // CONNECT PINS AS NECESSARY :
    // FIRST THE LAYERS TO THE MIXER
    [imagePin connectToPin:mixerPin];
    [mixerPin connectToPin:moviePin];
    // AND THEN THE MIXER TO THE SCREEN
    [mixerOut connectToPin:screenInput];
    [screenInput2 connectToPin:mixerOut];


    // START EVERYTHING
    [imageLayer start];
    [movieLayer start];
    [mixer start];
    
    // CONNECT A CALLBACK TO THE MIXER OUTPUT PIN TO GET EFFECTIVE FREQUENCY AND PRINT IT OUT
    [mixer attachObject:self withSelector:@"printFrequency:andSender:" toOutputPin:@"outputFrequency"];
    [imageLayer attachObject:self withSelector:@"printFrequency:andSender:" toOutputPin:@"outputFrequency"];
    
    /* END OF TEST CODE */
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
