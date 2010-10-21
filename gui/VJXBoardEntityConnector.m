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
#import "VJXBoardView.h"

@implementation VJXBoardEntityConnector

@synthesize selected;
@synthesize direction;
@synthesize origin;
@synthesize destination;
@synthesize board;

#define CONNECTOR_LINE_WIDTH 2.0
#define ORIGIN_OFFSET 10.0
#define DESTINATION_OFFSET 20.0

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

- (BOOL)isFlipped
{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *thePath = [[NSBezierPath alloc] init];

#if 0
    [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:0.25] setFill];
    [thePath appendBezierPathWithRect:[self bounds]];
    [thePath fill];
    [thePath closePath];
#endif
    [thePath setLineWidth:CONNECTOR_LINE_WIDTH];

    NSPoint initialPoint, endPoint, controlPoint1, controlPoint2;
    NSRect frame = [self frame];

    float scale = frame.size.width > frame.size.height
    ? frame.size.width / frame.size.height
    : frame.size.height / frame.size.width;

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        initialPoint = NSMakePoint(ORIGIN_OFFSET, frame.size.height - ORIGIN_OFFSET);
        endPoint = NSMakePoint(frame.size.width - ORIGIN_OFFSET, ORIGIN_OFFSET);
        controlPoint1 = NSMakePoint(frame.size.width / scale, frame.size.height - ORIGIN_OFFSET);
        controlPoint2 = NSMakePoint(frame.size.width - (frame.size.width / scale), ORIGIN_OFFSET);
    }
    else {
        initialPoint = NSMakePoint(ORIGIN_OFFSET, ORIGIN_OFFSET);
        endPoint = NSMakePoint(frame.size.width - ORIGIN_OFFSET, frame.size.height - ORIGIN_OFFSET);
        controlPoint1 = NSMakePoint(frame.size.width / scale, ORIGIN_OFFSET);
        controlPoint2 = NSMakePoint(frame.size.width - (frame.size.width / scale), frame.size.height - ORIGIN_OFFSET);
    }

    [thePath moveToPoint:initialPoint];
    [thePath curveToPoint:endPoint controlPoint1:controlPoint1 controlPoint2:controlPoint2];
    [thePath setLineCapStyle:NSRoundLineCapStyle];

    if (self.selected)
        [[NSColor yellowColor] setStroke];
    else
        [[NSColor blackColor] setStroke];

    NSShadow *lineShadow = [[NSShadow alloc] init];
    [lineShadow setShadowColor:[NSColor blackColor]];
    [lineShadow setShadowBlurRadius:2.5];
    [lineShadow setShadowOffset:NSMakeSize(CONNECTOR_LINE_WIDTH, - CONNECTOR_LINE_WIDTH)];
    [lineShadow set];

    [thePath stroke];

    [thePath release];
    [lineShadow release];
}

- (void)recalculateFrame
{
    NSPoint originLocation = [origin convertPoint:[origin pointAtCenter] toView:board];
    NSPoint destinationLocation = [destination convertPoint:[destination pointAtCenter] toView:board];

    float x = MIN(originLocation.x, destinationLocation.x) - ORIGIN_OFFSET;
    float y = MIN(originLocation.y, destinationLocation.y) - ORIGIN_OFFSET;
    float w = abs(originLocation.x - destinationLocation.x) + DESTINATION_OFFSET;
    float h = abs(originLocation.y - destinationLocation.y) + DESTINATION_OFFSET;

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
    [board toggleSelected:self multiple:isMultiple];
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
