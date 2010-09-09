//
//  VJXBoardComponentConnector.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXBoardEntityConnector.h"
#import "VJXBoard.h"

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
    NSBezierPath *thePath = [[NSBezierPath alloc] init];

    [thePath setLineWidth:2.0];

    NSPoint initialPoint, endPoint, controlPoint1, controlPoint2;

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        initialPoint = NSMakePoint(0.0, [self frame].size.height - 2.0);
        endPoint = NSMakePoint([self frame].size.width, 2.0);
        controlPoint1 = NSMakePoint([self frame].size.width / 3, [self frame].size.height);
        controlPoint2 = NSMakePoint([self frame].size.width / 3, [self frame].size.height);
    }
    else {
        initialPoint = NSMakePoint(0.0, 2.0);
        endPoint = NSMakePoint([self frame].size.width, [self frame].size.height - 2.0);
        controlPoint1 = NSMakePoint([self frame].size.width / 3, 0.0);
        controlPoint2 = NSMakePoint([self frame].size.width / 3, 0.0);
    }

    [thePath moveToPoint:initialPoint];
    [thePath curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [thePath setLineCapStyle:NSRoundLineCapStyle];

    [[NSColor blackColor] set];
    [thePath stroke];
    
    [thePath release];
}

- (void)recalculateFrame
{
    VJXBoard *board = [VJXBoard sharedBoard];
    
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

- (void)disconnect
{
    [self.origin removeConnector:self];
    [self.destination removeConnector:self];
}

@end
