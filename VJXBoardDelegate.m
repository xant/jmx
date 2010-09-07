//
//  VJXBoardDelegate.m
//  VeeJay
//
//  Created by Igor Sutton on 8/27/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXBoardDelegate.h"
#import "VJXBoardEntity.h"
#import "VJXQtVideoLayer.h"
#import "VJXOpenGLScreen.h"

@implementation VJXBoardDelegate

@synthesize board;

static id sharedBoard = nil;

+ (void)setSharedBoard:(id)aBoard
{
    sharedBoard = aBoard;
}

+ (id)sharedBoard
{
    return sharedBoard;
}

- (void)awakeFromNib
{
    [VJXBoardDelegate setSharedBoard:board];
}

- (IBAction)addEntity:(id)sender
{
    NSRect frame = NSMakeRect(10.0, 10.0, 200.0, 100.0);
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithFrame:frame];
    [board addSubview:entity];
    [board setNeedsDisplay:YES];
}

- (IBAction)addMovieLayer:(id)sender
{
    VJXQtVideoLayer *movieLayer = [[VJXQtVideoLayer alloc] init];
    movieLayer.moviePath = [@"~/test.avi" stringByExpandingTildeInPath];
    [movieLayer loadMovie];

    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithEntity:movieLayer];
    [board addSubview:entity];
    [movieLayer start];
}

- (IBAction)addImageLayer:(id)sender
{
    
}

- (IBAction)addOutputScreen:(id)sender
{
    VJXOpenGLScreen *screen = [[VJXOpenGLScreen alloc] init];
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithEntity:screen];
    [board addSubview:entity];
    NSLog(@"%s", _cmd);
}


@end
