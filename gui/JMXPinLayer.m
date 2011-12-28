//
//  JMXBoardComponentOutlet.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import "JMXPinLayer.h"
#import "JMXBoardView.h"
#import "JMXConnectorLayer.h"

@implementation JMXPinLayer

@synthesize selected;
@synthesize pin;

- (void)aPinWasDisconnected:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    JMXPin *inputPin = [userInfo objectForKey:@"inputPin"];
    JMXPin *outputPin = [userInfo objectForKey:@"outputPin"];
    JMXConnectorLayer *toDisconnect = nil;
    for (JMXConnectorLayer *connector in connectors) {
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
    if (toDisconnect)
        [toDisconnect removeConnectors];
}

- (void)aPinWasConnected:(NSNotification *)notification
{
    // do whatever necessary
}

- (id)initWithPin:(JMXPin *)thePin andPoint:(NSPoint)thePoint outlet:(JMXOutletLayer *)anOutlet
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
                                                     name:@"JMXPinConnected"
                                                   object:thePin];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(aPinWasDisconnected:)
                                                     name:@"JMXPinDisconnected"
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
    // NOTE: observers MUST be removed only after removeAllConnectors has finished
    //       and the underlying pin has been released, otherwise we could miss
    //       notifications sent by proxypins (which actually catch the notification
    //       from the real pin and propagates it to upper layers knowing only about 
    //       the proxy instance.
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinConnected" object:pin];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinDisconnected" object:pin];
    [super dealloc];
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
    [connectors makeObjectsPerformSelector:@selector(recalculateFrame)];
}

- (BOOL)multiple
{
    return pin.multiple;
}

- (BOOL)isConnected
{
    NSUInteger count;
    count = [connectors count] ? YES : NO;
    return count;
}

- (void)addConnector:(JMXConnectorLayer *)theConnector
{
    [connectors addObject:theConnector];
}

- (void)removeConnector:(JMXConnectorLayer *)theConnector
{
    [connectors removeObject:theConnector];
}

- (void)removeAllConnectors
{
    NSArray *objs = [connectors copy];
    for (JMXConnectorLayer *connector in objs)
        [connector disconnect];
    [objs release];
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
    CGColorRef backgroundColor_ = CGColorCreateGenericRGB(0.0f, 1.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor_;
    CFRelease(backgroundColor_);
}

- (void)unfocus
{
    CGColorRef backgroundColor_ = CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f);
    self.backgroundColor = backgroundColor_;
    CFRelease(backgroundColor_);
}

@end
