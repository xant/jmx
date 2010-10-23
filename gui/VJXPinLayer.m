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

- (void)aPinWasDisconnected:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    VJXPin *inputPin = [userInfo objectForKey:@"inputPin"];
    VJXPin *outputPin = [userInfo objectForKey:@"outputPin"];
    VJXConnectorLayer *toDisconnect = nil;
    @synchronized(connectors) {
        for (VJXConnectorLayer *connector in connectors) {
            if (connector.originPinLayer == self) {
                if (connector.destinationPinLayer.pin == inputPin ||
                    connector.destinationPinLayer.pin == outputPin)
                {
                    toDisconnect = connector;
                    break;
                }
            } else {
                if (connector.originPinLayer.pin == inputPin ||
                    connector.originPinLayer.pin == outputPin)
                {
                    toDisconnect = connector;
                    break;
                }
            }
        }
    }
    if (toDisconnect)
        [toDisconnect disconnect];
}

- (void)aPinWasConnected:(NSNotification *)notification
{
    // do whatever necessary
}

- (id)initWithPin:(VJXPin *)thePin andPoint:(CGPoint)thePoint outlet:(VJXOutletLayer *)anOutlet
{
    self = [super init];
    if (self) {
        outlet = anOutlet;
        selected = NO;
        connectors = [[NSMutableArray alloc] init];
        self.frame = CGRectMake(thePoint.x, thePoint.y, PIN_OUTLET_WIDTH, PIN_OUTLET_HEIGHT);
        pin = [thePin retain];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(aPinWasConnected:) 
                                                     name:@"VJXPinConnected"
                                                   object:thePin];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(aPinWasDisconnected:) 
                                                     name:@"VJXPinDisconnected"
                                                   object:thePin];
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

- (CGPoint)pointAtCenter
{
    CGPoint origin = [self bounds].origin;
    CGSize size = [self bounds].size;
    CGPoint center = CGPointMake(origin.x + (size.width / 2), origin.y + (size.height / 2));
    return center;
}

- (void)updateAllConnectorsFrames
{
    @synchronized(connectors) {
        [connectors makeObjectsPerformSelector:@selector(recalculateFrame)];
    }
}

- (BOOL)multiple
{
    return pin.multiple;
}

- (BOOL)isConnected
{
    NSUInteger count;
    @synchronized(connectors) {
        count = [connectors count] ? YES : NO;
    }
    return count;
}

- (void)addConnector:(VJXConnectorLayer *)theConnector
{
    @synchronized(connectors) {
        [connectors addObject:theConnector];
    }
}

- (void)removeConnector:(VJXConnectorLayer *)theConnector
{
    @synchronized(connectors) {
        [connectors removeObject:theConnector];
    }
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
