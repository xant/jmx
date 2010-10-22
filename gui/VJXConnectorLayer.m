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

#import "VJXConnectorLayer.h"
#import "VJXBoardView.h"

@implementation VJXConnectorLayer

@synthesize selected;
@synthesize direction;
@synthesize originPinLayer;
@synthesize destinationPinLayer;
@synthesize boardView;
@synthesize initialPosition;

- (id)initWithOriginPinLayer:(VJXPinLayer *)anOriginPinLayer
{
    self = [super init];
    if (self) {
        self.originPinLayer = anOriginPinLayer;
        self.destinationPinLayer = nil;
    }
    return self;
}

- (void)dealloc
{
    self.originPinLayer = nil;
    self.destinationPinLayer = nil;
    [super dealloc];
}

- (void)drawInContext:(CGContextRef)theContext
{
    CGContextSaveGState(theContext);

    CGColorRef backgroundColor_ = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.1f);
    CGColorRef foregroundColor_ = CGColorCreateGenericRGB(0.0f, 0.0f, 0.0f, 0.5f);

    CGMutablePathRef thePath = CGPathCreateMutable();

    CGContextSetFillColorWithColor(theContext, backgroundColor_);
    CGContextSetStrokeColorWithColor(theContext, foregroundColor_);

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

    CGPathMoveToPoint(thePath, NULL, initialPoint.x, initialPoint.y);
    CGPathAddCurveToPoint(thePath, NULL, controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, endPoint.x, endPoint.y);

    CGContextAddPath(theContext, thePath);
    CGContextSetLineWidth(theContext, CONNECTOR_LINE_WIDTH);
    CGContextStrokePath(theContext);

    CFRelease(thePath);
    CFRelease(backgroundColor_);
    CFRelease(foregroundColor_);

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

- (void)disconnect
{
    [self removeFromSuperlayer];
    NSLog(@"retain1 %d", [self retainCount]);
    [originPinLayer removeConnector:self];
    [destinationPinLayer removeConnector:self];
    self.originPinLayer = nil;
    self.destinationPinLayer = nil;
    NSLog(@"retain2 %d", [self retainCount]);
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (void)setSelected:(BOOL)isSelected
{
    selected = isSelected;
    [self setNeedsDisplay];
}

@end
