//
//  VJXBoardDelegate.m
//  VeeJay
//
//  Created by Igor Sutton on 8/27/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXBoardDelegate.h"
#import "VJXBoardEntity.h"


@implementation VJXBoardDelegate

@synthesize board;

- (IBAction)addEntity:(id)sender
{
    NSRect frame = NSMakeRect(10.0, 10.0, 200.0, 100.0);
    VJXBoardEntity *entity = [[VJXBoardEntity alloc] initWithFrame:frame];
    [board addSubview:entity];
    [board setNeedsDisplay:YES];
}

@end
