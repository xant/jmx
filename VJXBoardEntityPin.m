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
#import "VJXBoardDelegate.h"
#import "VJXBoardEntityConnector.h"

@implementation VJXBoardEntityPin

@synthesize pin, connectors;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint
{
    NSRect frame = NSMakeRect(thePoint.x, thePoint.y, 18.0, 18.0);
    
    if ((self = [super initWithFrame:frame]) != nil) {
        connectors = [[NSMutableArray alloc] init];
        pin = [thePin retain];        
    }
    return self;
}

- (void)dealloc
{
    if (connectors)
        [connectors release];
    if (pin)
        [pin release];
    if (tempConnector)
        [tempConnector release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSRect bounds = [self bounds];
    
    bounds.origin.x += 5.0;
    bounds.origin.y += 5.0;
    bounds.size.width -= (2 * bounds.origin.x);
    bounds.size.height -= (2 * bounds.origin.y);
    
    NSBezierPath *thePath = nil;
    [[NSColor whiteColor] setFill];
    thePath = [[NSBezierPath alloc] init];
    [thePath setLineWidth:2.0];
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
        [[VJXBoardDelegate sharedBoard] addSubview:tempConnector positioned:NSWindowBelow relativeTo:nil];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];

    NSPoint thisLocation = [self convertPoint:[self pointAtCenter] toView:[VJXBoardDelegate sharedBoard]];

    float minX = MIN(locationInWindow.x, thisLocation.x);
    float minY = MIN(locationInWindow.y, thisLocation.y);
    float width = abs(locationInWindow.x - thisLocation.x);
    float height = abs(locationInWindow.y - thisLocation.y);

    if (width < 5.0) {
        width = 5.0;
    }
    if (height < 5.0) {
        height = 5.0;
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
    [self.superview setNeedsDisplay:YES];

}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationInWindow = [theEvent locationInWindow];
    
    NSView *aView = [[VJXBoardDelegate sharedBoard] hitTest:locationInWindow];
    
    if ([aView isKindOfClass:[VJXBoardEntityPin class]]) {
        
        VJXBoardEntityPin *otherPin = (VJXBoardEntityPin *)aView;
        
        NSLog(@"this Pin: %@, other Pin: %@", self.pin.name, otherPin.pin.name);
        
        if ([otherPin isConnected] && ![otherPin multiple])
            [otherPin removeAllConnectors];

        [otherPin.pin connectToPin:self.pin];

        [tempConnector setOrigin:self];
        [tempConnector setDestination:otherPin];

        [otherPin addConnector:tempConnector];
        [self addConnector:tempConnector];
        
        [self updateAllConnectorsFrames];
        
        [tempConnector release];
        tempConnector = nil;
    }
    else {
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

@end
