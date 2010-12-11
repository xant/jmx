//
//  JMXBoardComponentConnector.m
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

#import "JMXConnectorLayer.h"
#import "JMXBoardView.h"

@implementation JMXConnectorLayer

@synthesize selected;
@synthesize direction;
@synthesize originPinLayer;
@synthesize destinationPinLayer;
@synthesize boardView;
@synthesize initialPosition;
@synthesize foregroundColor;

- (id)initWithOriginPinLayer:(JMXPinLayer *)anOriginPinLayer
{
    self = [super init];
    if (self) {
        self.originPinLayer = anOriginPinLayer;
        self.destinationPinLayer = nil;
        self.foregroundColor = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);

        path = NULL;
    }
    return self;
}

- (void)dealloc
{
    self.originPinLayer = nil;
    self.destinationPinLayer = nil;
    if (path)
        CFRelease(path);
    [super dealloc];
}

- (BOOL)containsPoint:(CGPoint)p
{
    // This connector is still temporary and we don't want it to return to the
    // hit test. Once the connection is complete, we can respond to it.
    if (self.originPinLayer == nil || self.destinationPinLayer == nil)
        return NO;
    
    CGContextRef theContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
    BOOL containsPoint = NO;

    CGContextSaveGState(theContext);

    CGContextAddPath(theContext, path);
    containsPoint = CGContextPathContainsPoint(theContext, p, kCGPathFillStroke);
    CGContextRestoreGState(theContext);

    return containsPoint;
}

- (void)drawInContext:(CGContextRef)theContext
{
    CGContextSaveGState(theContext);

    if (path)
        CFRelease(path);

    path = CGPathCreateMutable();

    CGContextSetFillColorWithColor(theContext, self.foregroundColor);

    CGPoint initialPoint, endPoint, controlPoint1, controlPoint2;

    CGRect frame = self.bounds;

    CGFloat scale = frame.size.width > frame.size.height
                  ? frame.size.width / frame.size.height
                  : frame.size.height / frame.size.width;

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        initialPoint = CGPointMake(ORIGIN_OFFSET, frame.size.height - ORIGIN_OFFSET);
        endPoint = CGPointMake(frame.size.width - ORIGIN_OFFSET, ORIGIN_OFFSET);
        controlPoint1 = CGPointMake(frame.size.width / scale, frame.size.height - ORIGIN_OFFSET);
        controlPoint2 = CGPointMake(frame.size.width - (frame.size.width / scale), ORIGIN_OFFSET);
    }
    else {
        initialPoint = CGPointMake(ORIGIN_OFFSET, ORIGIN_OFFSET);
        endPoint = CGPointMake(frame.size.width - ORIGIN_OFFSET, frame.size.height - ORIGIN_OFFSET);
        controlPoint1 = CGPointMake(frame.size.width / scale, ORIGIN_OFFSET);
        controlPoint2 = CGPointMake(frame.size.width - (frame.size.width / scale), frame.size.height - ORIGIN_OFFSET);
    }

    CGPathMoveToPoint(path, NULL, initialPoint.x, initialPoint.y);
    CGPathAddCurveToPoint(path, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);

    if ((direction == kSouthEastDirection) || (direction == kNorthWestDirection)) {
        controlPoint2.x -= 3.535533906f / scale;
        controlPoint2.y -= 3.535533906f / scale;
        controlPoint1.x -= 3.535533906f / scale;
        controlPoint1.y -= 3.535533906f / scale;
        CGPathAddLineToPoint(path, NULL, endPoint.x - CONNECTOR_LINE_WIDTH, endPoint.y - CONNECTOR_LINE_WIDTH);
        CGPathAddCurveToPoint(path, NULL, controlPoint2.x, controlPoint2.y, controlPoint1.x, controlPoint1.y, initialPoint.x - CONNECTOR_LINE_WIDTH, initialPoint.y - CONNECTOR_LINE_WIDTH);
        CGPathAddLineToPoint(path, NULL, initialPoint.x - CONNECTOR_LINE_WIDTH, initialPoint.y - CONNECTOR_LINE_WIDTH);
    }
    else {
        controlPoint2.x += 3.535533906f / scale;
        controlPoint2.y -= 3.535533906f / scale;
        controlPoint1.x += 3.535533906f / scale;
        controlPoint1.y -= 3.535533906f / scale;
        CGPathAddLineToPoint(path, NULL, endPoint.x + CONNECTOR_LINE_WIDTH, endPoint.y - CONNECTOR_LINE_WIDTH);
        CGPathAddCurveToPoint(path, NULL, controlPoint2.x, controlPoint2.y, controlPoint1.x, controlPoint1.y, initialPoint.x + CONNECTOR_LINE_WIDTH, initialPoint.y - CONNECTOR_LINE_WIDTH);
        CGPathAddLineToPoint(path, NULL, initialPoint.x + CONNECTOR_LINE_WIDTH, initialPoint.y - CONNECTOR_LINE_WIDTH);
    }


    CGContextAddPath(theContext, path);
    CGContextClosePath(theContext);
    CGContextFillPath(theContext);

    CGContextRestoreGState(theContext);
}

- (void)recalculateFrameWithPoint:(CGPoint)aPoint
{
    [self recalculateFrameWithPoint:aPoint andPoint:self.initialPosition];
}

- (void)recalculateFrameWithPoint:(CGPoint)originPoint andPoint:(CGPoint)destinationPoint
{
    direction =
    ((originPoint.x < destinationPoint.x) && (originPoint.y < destinationPoint.y))
    ? kSouthWestDirection
    : ((originPoint.x > destinationPoint.x) && (originPoint.y < destinationPoint.y))
    ? kSouthEastDirection
    : ((originPoint.x > destinationPoint.x) && (originPoint.y > destinationPoint.y))
    ? kNorthEastDirection
    : kNorthWestDirection;

    CGFloat x = MIN(originPoint.x, destinationPoint.x) - ORIGIN_OFFSET;
    CGFloat y = MIN(originPoint.y, destinationPoint.y) - ORIGIN_OFFSET;
    CGFloat w = abs(originPoint.x - destinationPoint.x) + DESTINATION_OFFSET;
    CGFloat h = abs(originPoint.y - destinationPoint.y) + DESTINATION_OFFSET;

    self.frame = CGRectMake(x, y, w, h);
    [self setNeedsDisplay];
}

- (void)recalculateFrame
{
    CGPoint originPoint = [boardView.layer convertPoint:[originPinLayer pointAtCenter] fromLayer:originPinLayer];
    CGPoint destinationPoint = [boardView.layer convertPoint:[destinationPinLayer pointAtCenter] fromLayer:destinationPinLayer];
    [self recalculateFrameWithPoint:originPoint andPoint:destinationPoint];
}

- (void)removeConnectors
{
    [self removeFromSuperlayer];
    [originPinLayer removeConnector:self];
    [destinationPinLayer removeConnector:self];
    self.originPinLayer = nil;
    self.destinationPinLayer = nil;
}

- (void)disconnect
{
    [originPinLayer.pin disconnectFromPin:destinationPinLayer.pin];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (void)setSelected:(BOOL)isSelected
{
    selected = isSelected;
    self.foregroundColor = selected ? CGColorCreateGenericRGB(1.0f, 0.0f, 0.0f, 1.0f) : CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);
    [self setNeedsDisplay];
}

- (void)setForegroundColor:(CGColorRef)aColor
{
    if (foregroundColor)
        CFRelease(foregroundColor);
    foregroundColor = aColor;
}

- (void)select
{
    self.selected = YES;
}

- (void)unselect
{
    self.selected = NO;
}

- (BOOL)originCanConnectTo:(JMXPinLayer *)aPinLayer
{
    if (aPinLayer == nil)
        return NO;
    return [self.originPinLayer.pin canConnectToPin:aPinLayer.pin];
}

@end
