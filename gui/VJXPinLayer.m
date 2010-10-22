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

#import "VJXPinLayer.h"
#import "VJXBoardView.h"
#import "VJXConnectorLayer.h"

@implementation VJXPinLayer

@synthesize selected;
@synthesize pin;
@synthesize connectors;

- (id)initWithPin:(VJXPin *)thePin andPoint:(CGPoint)thePoint outlet:(VJXOutletLayer *)anOutlet
{
    if ((self = [super init]) != nil) {
        outlet = anOutlet;
        selected = NO;
        connectors = [[NSMutableArray alloc] init];
        self.frame = CGRectMake(thePoint.x, thePoint.y, PIN_OUTLET_WIDTH, PIN_OUTLET_HEIGHT);
        pin = [thePin retain];
        [self setupLayer];
    }
    return self;
}

- (void)setupLayer
{
    CGColorRef backgroundColor_ = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor_;
    self.borderColor = NULL;
    self.borderWidth = 0.0f;
    CFRelease(backgroundColor_);
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)dealloc
{
    if (connectors) {
        [self removeAllConnectors];
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

- (void)mouseDown:(NSEvent *)theEvent
{
}

//- (void)mouseDragged:(NSEvent *)theEvent
//{
//    VJXBoardView *board = outlet.entity.board;
//
//    if (!tempConnector) {
//        tempConnector = [[VJXBoardEntityConnector alloc] init];
//        tempConnector.origin = self;
//        tempConnector.board = board;
//        [board addSubview:tempConnector positioned:NSWindowAbove relativeTo:self];
//    }
//
//    NSPoint locationInWindow = [board convertPoint:[theEvent locationInWindow] fromView:nil];
//
//    NSPoint thisLocation = [self convertPoint:[self pointAtCenter] toView:board];
//
//    float minX = MIN(locationInWindow.x, thisLocation.x) - 10.0;
//    float minY = MIN(locationInWindow.y, thisLocation.y) - 10.0;
//    float width = abs(locationInWindow.x - thisLocation.x) + 20.0;
//    float height = abs(locationInWindow.y - thisLocation.y) + 20.0;
//
//    if (width < 6.0) {
//        width = 6.0;
//    }
//    if (height < 6.0) {
//        height = 6.0;
//    }
//
//    if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
//        tempConnector.direction = kSouthWestDirection;
//    }
//    else if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
//        tempConnector.direction = kSouthEastDirection;
//    }
//    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
//        tempConnector.direction = kNorthWestDirection;
//    }
//    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
//        tempConnector.direction = kNorthEastDirection;
//    }
//
//    NSRect frame = NSMakeRect(minX, minY, width, height);
//    [tempConnector setFrame:frame];
//}
//
//- (void)mouseUp:(NSEvent *)theEvent
//{
//    VJXBoardView *board = outlet.entity.board;
//
//    NSPoint locationInWindow = [board convertPoint:[theEvent locationInWindow] fromView:nil];
//    locationInWindow.x -= PIN_OUTLET_PADDING;
//    locationInWindow.y -= PIN_OUTLET_PADDING;
//    NSView *aView = [board hitTest:locationInWindow];
//
//    BOOL isConnected = NO;
//
//    if ([aView isKindOfClass:[VJXPinLayer class]]) {
//
//        VJXPinLayer *otherPin = (VJXPinLayer *)aView;
//
//        if ([otherPin isConnected] && ![otherPin multiple])
//            [otherPin removeAllConnectors];
//
//        isConnected = [otherPin.pin connectToPin:self.pin];
//
//        if (isConnected) {
//            [tempConnector setOrigin:self];
//            [tempConnector setDestination:otherPin];
//
//            [otherPin addConnector:tempConnector];
//            [self addConnector:tempConnector];
//
//            [self updateAllConnectorsFrames];
//
//            [tempConnector release];
//            tempConnector = nil;
//        }
//    }
//
//    if (!isConnected) {
//        [tempConnector removeFromSuperlayer];
//        [tempConnector release];
//        tempConnector = nil;
//    }
//}
//

- (CGPoint)pointAtCenter
{
    CGPoint origin = [self bounds].origin;
    CGSize size = [self bounds].size;
    CGPoint center = CGPointMake(origin.x + (size.width / 2), origin.y + (size.height / 2));
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

- (void)addConnector:(VJXConnectorLayer *)theConnector
{
    [connectors addObject:theConnector];
}

- (void)removeConnector:(VJXConnectorLayer *)theConnector
{
    [connectors removeObject:theConnector];
}

- (void)removeAllConnectors
{
//    for (VJXConnectorLayer *connector in connectors) {
//        if (connector.origin == self) {
//            [connector.destination removeConnector:connector];
//        } else {
//            [connector.origin removeConnector:connector];
//        }
//        [connector removeFromSuperview];
//    }
//    [connectors removeAllObjects];
}

- (void)setSelected:(BOOL)isSelected
{
    selected = isSelected;
    [self setNeedsDisplay];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (void)focus
{
    CGColorRef *backgroundColor_ = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor_;
    CFRelease(backgroundColor_);
}

- (void)unfocus
{
    CGColorRef *backgroundColor_ = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor_;
    CFRelease(backgroundColor_);
}

@end
