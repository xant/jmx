//
//  VJXBoardComponentConnector.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntityConnector.h"
#import "VJXBoardDelegate.h"

@implementation VJXBoardEntityConnector

@synthesize direction, origin, destination;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
    [self setOrigin:nil];
    [self setDestination:nil];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.2] set];

    NSBezierPath *thePath = [[NSBezierPath alloc] init];

    [thePath appendBezierPathWithRect:[self bounds]];
    [thePath fill];

    [thePath setLineWidth:2.0];

    NSPoint initialPoint, endPoint, controlPoint1, controlPoint2;

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        initialPoint = NSMakePoint(0.0, [self frame].size.height - 2.0);
        endPoint = NSMakePoint([self frame].size.width, 2.0);
        controlPoint1 = NSMakePoint([self frame].size.width, [self frame].size.height);
        controlPoint2 = NSMakePoint(0.0, 0.0);
    }
    else {
        initialPoint = NSMakePoint(0.0, 2.0);
        endPoint = NSMakePoint([self frame].size.width, [self frame].size.height - 2.0);
        controlPoint1 = NSMakePoint([self frame].size.width, 0.0);
        controlPoint2 = NSMakePoint(0, [self frame].size.height);
    }

    [thePath moveToPoint:initialPoint];
    [thePath curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];

    [[NSColor blackColor] setStroke];
    [thePath stroke];
    [thePath release];
}

- (void)recalculateFrame
{
    VJXBoard *board = [VJXBoardDelegate sharedBoard];
    
    NSPoint originLocation = [origin convertPoint:[origin pointAtCenter] toView:board];
    NSPoint destinationLocation = [destination convertPoint:[destination pointAtCenter] toView:board];
    
    float x = MIN(originLocation.x, destinationLocation.x);
    float y = MIN(originLocation.y, destinationLocation.y);
    float w = abs(originLocation.x - destinationLocation.x);
    float h = abs(originLocation.y - destinationLocation.y);
    
    direction =
    ((originLocation.x < destinationLocation.x) && (originLocation.y < destinationLocation.y))
    ? kSouthWestDirection
    : ((originLocation.x > destinationLocation.x) && (originLocation.y < destinationLocation.y))
    ? kSouthEastDirection
    : ((originLocation.x > destinationLocation.x) && (originLocation.y > destinationLocation.y))
    ? kNorthEastDirection
    : kNorthWestDirection;
    
    NSRect frame = NSMakeRect(x, y, w, h);
    [self setFrame:frame];
}


@end
