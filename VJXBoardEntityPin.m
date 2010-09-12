//
//  VJXBoardComponentOutlet.m
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

#import "VJXBoardEntityPin.h"
#import "VJXBoard.h"
#import "VJXBoardEntityConnector.h"

#define PIN_OUTLET_PADDING 5.0
#define PIN_OUTLET_WIDTH 18.0
#define PIN_OUTLET_HEIGHT 18.0

@implementation VJXBoardEntityPin

@synthesize selected, pin, connectors;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint
{
    NSRect frame = NSMakeRect(thePoint.x, thePoint.y, PIN_OUTLET_WIDTH, PIN_OUTLET_HEIGHT);
    
    if ((self = [super initWithFrame:frame]) != nil) {
        selected = NO;
        connectors = [[NSMutableArray alloc] init];
        pin = [thePin retain];        
    }
    return self;
}

- (void)dealloc
{
    if (connectors) {
        for (VJXBoardEntityConnector *connector in connectors) {
            // since the connector is retained by both us and the other 
            // side of the connection (damn circular references!!)
            // we need to ensure releasing it in both sides
            [connector.origin removeConnector:connector];
            [connector.destination removeConnector:connector];
            // and now , we still need to remove the connector from the superview
            // (which is also retaining it)
            [connector removeFromSuperview];
        }
        [connectors release];
    }
    if (pin)
        [pin release];
    if (tempConnector)
        [tempConnector release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    
    bounds.origin.x += PIN_OUTLET_PADDING;
    bounds.origin.y += PIN_OUTLET_PADDING;
    bounds.size.width -= (2 * bounds.origin.x);
    bounds.size.height -= (2 * bounds.origin.y);
    
    NSBezierPath *thePath = nil;
    
    if (self.selected == YES) 
        [[NSColor yellowColor] setFill];
    else
        [[NSColor whiteColor] setFill];
    
    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithOvalInRect:bounds];
    [thePath fill];
        
    [thePath release];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{

}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!tempConnector) {
        tempConnector = [[VJXBoardEntityConnector alloc] init];
        [tempConnector setOrigin:self];
        [[VJXBoard sharedBoard] addSubview:tempConnector positioned:NSWindowBelow relativeTo:nil];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];

    NSPoint thisLocation = [self convertPoint:[self pointAtCenter] toView:[VJXBoard sharedBoard]];

    float minX = MIN(locationInWindow.x, thisLocation.x) - 10.0;
    float minY = MIN(locationInWindow.y, thisLocation.y) - 10.0;
    float width = abs(locationInWindow.x - thisLocation.x) + 20.0;
    float height = abs(locationInWindow.y - thisLocation.y) + 20.0;

    if (width < 6.0) {
        width = 6.0;
    }
    if (height < 6.0) {
        height = 6.0;
    }

    if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        tempConnector.direction = kSouthWestDirection;
    }
    else if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        tempConnector.direction = kSouthEastDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        tempConnector.direction = kNorthWestDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        tempConnector.direction = kNorthEastDirection;
    }

    NSRect frame = NSMakeRect(minX, minY, width, height);
    [tempConnector setFrame:frame];

}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationInWindow = [theEvent locationInWindow];
    locationInWindow.x -= PIN_OUTLET_PADDING;
    locationInWindow.y -= PIN_OUTLET_PADDING;
    NSView *aView = [[VJXBoard sharedBoard] hitTest:locationInWindow];
    
    BOOL isConnected = NO;
    
    if ([aView isKindOfClass:[VJXBoardEntityPin class]]) {
        
        VJXBoardEntityPin *otherPin = (VJXBoardEntityPin *)aView;
        
        if ([otherPin isConnected] && ![otherPin multiple])
            [otherPin removeAllConnectors];

        isConnected = [otherPin.pin connectToPin:self.pin];

        if (isConnected) {
            [tempConnector setOrigin:self];
            [tempConnector setDestination:otherPin];
            
            [otherPin addConnector:tempConnector];
            [self addConnector:tempConnector];
            
            [self updateAllConnectorsFrames];
            
            [tempConnector release];
            tempConnector = nil;            
        }
    }
    
    if (!isConnected) {        
        [tempConnector removeFromSuperview];
        [tempConnector release];
        tempConnector = nil;
    }
}

- (NSPoint)pointAtCenter
{
    NSPoint origin = [self bounds].origin;
    NSSize size = [self bounds].size;
    NSPoint center = NSMakePoint(origin.x + (size.width / 2), origin.y + (size.height / 2));
    return center;
}

- (void)updateAllConnectorsFrames
{
    [connectors makeObjectsPerformSelector:@selector(recalculateFrame)];
}

- (BOOL)multiple
{
    return pin.multiple;
}

- (BOOL)isConnected
{
    return [connectors count] ? YES : NO;
}

- (void)addConnector:(VJXBoardEntityConnector *)theConnector
{
    [connectors addObject:theConnector];
}

- (void)removeConnector:(VJXBoardEntityConnector *)theConnector
{
    [connectors removeObject:theConnector];
}

- (void)removeAllConnectors
{
    for (VJXBoardEntityConnector *connector in connectors) {
        if (connector.origin == self) {
            [connector.destination removeConnector:connector];
        } else {
            [connector.origin removeConnector:connector];
        }
        [connector removeFromSuperview];
    }
    [connectors removeAllObjects];
}

- (void)setSelected:(BOOL)isSelected
{
    selected = isSelected;
    [self setNeedsDisplay:YES];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

@end
