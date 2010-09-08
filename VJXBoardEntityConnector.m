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

//- (void)drawRect:(NSRect)dirtyRect {
//    NSBezierPath *thePath = [[NSBezierPath alloc] init];
//
//    [[NSColor blackColor] set];
//
//    NSPoint start, end;
//    NSRect bounds = [self bounds];
//
//    if ((direction == 0) || (direction == 3)) {
//        start = bounds.origin;
//        end = NSMakePoint(bounds.size.width,
//                          bounds.size.height);
//    }
//    else if (direction == 1) {
//        start = NSMakePoint(bounds.origin.x, bounds.size.height);
//        end = NSMakePoint(bounds.size.width, bounds.origin.y);
//    }
//    else if (direction == 2) {
//        start = NSMakePoint(bounds.origin.x, bounds.size.height);
//        end = NSMakePoint(bounds.size.width, bounds.origin.y);
//    }
//
//    NSPointArray points;
//    points = (NSPointArray)calloc(2, sizeof(NSPoint));
//
//    points[0] = start;
//    points[1] = end;
//
//
//    [thePath appendBezierPathWithPoints:points count:2];
//    [thePath stroke];
//}

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
    NSPoint originPoint = [origin convertPoint:[origin pointAtCenter]
        toView:[VJXBoardDelegate sharedBoard]];

    NSPoint destinationPoint = [destination convertPoint:[destination pointAtCenter]
        toView:[VJXBoardDelegate sharedBoard]];

    NSLog(@"originPoint.x:%f originPoint.y:%f destinationPoint.x:%f destinationPoint.y:%f",
        originPoint.x,
        originPoint.y,
        destinationPoint.x,
        destinationPoint.y);

    NSLog(@"origin.x:%f origin.y:%f destination.x:%f destination.y:%f",
          [origin pointAtCenter].x,
          [origin pointAtCenter].y,
          [destination pointAtCenter].x,
          [destination pointAtCenter].y);
    
    float x = MIN(originPoint.x, destinationPoint.x);
    float y = MIN(originPoint.y, destinationPoint.y);
    float w = abs(originPoint.x - destinationPoint.x);
    float h = abs(originPoint.y - destinationPoint.y);

    direction =
        ((originPoint.x < destinationPoint.x) && (originPoint.y < destinationPoint.y))
        ? kSouthWestDirection
        : ((originPoint.x > destinationPoint.x) && (originPoint.y < destinationPoint.y))
        ? kSouthEastDirection
        : ((originPoint.x > destinationPoint.x) && (originPoint.y > destinationPoint.y))
        ? kNorthEastDirection
        : kNorthWestDirection;

    //if (h < 1.0) h = 2.0;
    //if (w < 1.0) w = 2.0;

    CGFloat entityWidth = 100.0;

    if ((direction == kSouthWestDirection) || (direction == kNorthWestDirection)) {
        float scale = entityWidth / entityWidth;
        x -= ((scale - 1) * entityWidth);
        w += ((scale - 1) * entityWidth);
    }
    else {
        float scale = entityWidth / entityWidth;
        x -= ((scale - 1) * entityWidth);
        w -= ((scale - 1) * entityWidth);
    }
    // entity's width / pin's width *

    NSRect frame = NSMakeRect(x, y, w, h);
    [self setFrame:frame];
}

@end
