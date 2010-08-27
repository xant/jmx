//
//  VJXBoardComponentConnector.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntityConnector.h"


@implementation VJXBoardEntityConnector

@synthesize direction, origin, destination;

- (id)initWithFrame:(NSRect)frame {
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

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *thePath = [[NSBezierPath alloc] init];

    [[NSColor blackColor] set];

    NSPoint start, end;
    NSRect bounds = [self bounds];

    if ((direction == 0) || (direction == 3)) {
        start = bounds.origin;
        end = NSMakePoint(bounds.size.width,
                          bounds.size.height);
    }
    else if (direction == 1) {
        start = NSMakePoint(bounds.origin.x, bounds.size.height);
        end = NSMakePoint(bounds.size.width, bounds.origin.y);
    }
    else if (direction == 2) {
        start = NSMakePoint(bounds.origin.x, bounds.size.height);
        end = NSMakePoint(bounds.size.width, bounds.origin.y);
    }

    NSPointArray points;
    points = (NSPointArray)calloc(2, sizeof(NSPoint));

    points[0] = start;
    points[1] = end;


    [thePath appendBezierPathWithPoints:points count:2];
    [thePath stroke];
}

@end
