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

@synthesize selected, direction, origin, destination;

#define CONNECTOR_LINE_WIDTH 2.0
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

    [thePath setLineWidth:CONNECTOR_LINE_WIDTH];

    NSPoint initialPoint, endPoint, controlPoint1, controlPoint2;

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        initialPoint = NSMakePoint(0.0, [self frame].size.height - CONNECTOR_LINE_WIDTH);
        if (initialPoint.y < 0.0)
            initialPoint.y = 0.0;
        endPoint = NSMakePoint([self frame].size.width - 6.0, CONNECTOR_LINE_WIDTH);
        controlPoint1 = NSMakePoint([self frame].size.width / 3, [self frame].size.height);
        controlPoint2 = NSMakePoint([self frame].size.width / 3, [self frame].size.height);
    }
    else {
        initialPoint = NSMakePoint(0.0, 2.0);
        endPoint = NSMakePoint([self frame].size.width - 6.0, [self frame].size.height - CONNECTOR_LINE_WIDTH);
        if (endPoint.y < 0.0)
            endPoint.y = 0.0;
        controlPoint1 = NSMakePoint(3.0, 0.0);
        controlPoint2 = NSMakePoint([self frame].size.width / 3, 0.0);
    }

    [thePath moveToPoint:initialPoint];
    [thePath curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [thePath setLineCapStyle:NSRoundLineCapStyle];

    if (self.selected)
        [[NSColor yellowColor] set];
    else
        [[NSColor blackColor] set];
    
    NSShadow *lineShadow = [[NSShadow alloc] init];
    [lineShadow setShadowColor:[NSColor blackColor]];
    [lineShadow setShadowBlurRadius:2.5];
    [lineShadow setShadowOffset:NSMakeSize(CONNECTOR_LINE_WIDTH, - CONNECTOR_LINE_WIDTH)];
    [lineShadow set];
    
    [thePath stroke];
    
    [thePath release];
  //  [lineShadow release];
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
    
    NSRect frame = NSMakeRect(x, y, w + CONNECTOR_LINE_WIDTH, h + CONNECTOR_LINE_WIDTH);
    [self setFrame:frame];
}

- (void)disconnect
{
    [self.origin removeConnector:self];
    [self.destination removeConnector:self];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    BOOL isMultiple = [theEvent modifierFlags] & NSCommandKeyMask ? YES : NO;
    [[VJXBoard sharedBoard] setSelected:self multiple:isMultiple];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
    [self.origin toggleSelected];
    [self.destination toggleSelected];
}

- (void)setSelected:(BOOL)isSelected
{
    selected = isSelected;
    [self setNeedsDisplay:YES];
}

@end
