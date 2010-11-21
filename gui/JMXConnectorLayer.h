//
//  JMXBoardComponentConnector.h
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "JMXPinLayer.h"
#import "JMXBoardView.h"
#import "JMXGUIConstants.h"

@class JMXPinLayer;
@class JMXBoardView;

enum Direction {
    kSouthEastDirection,
    kNorthEastDirection,
    kSouthWestDirection,
    kNorthWestDirection
};

@interface JMXConnectorLayer : CALayer {
    BOOL selected;
    JMXBoardView *boardView;
    CGPoint initialPosition;
    JMXPinLayer *originPinLayer;
    JMXPinLayer *destinationPinLayer;
    NSUInteger direction;
	CGMutablePathRef path;
	CGColorRef foregroundColor;
}

@property (assign) BOOL selected;
@property (assign) JMXBoardView *boardView;
@property (assign) CGPoint initialPosition;
@property (assign) NSUInteger direction;
@property (assign) CGColorRef foregroundColor;

// make this weak references otherwise pins will be overretained an never released
// the following two properties must be defined as atomic because can be accessed
// by differnt threads (since pins can be disconnected in any moment)
@property (assign) JMXPinLayer *originPinLayer;
@property (assign) JMXPinLayer *destinationPinLayer;

- (id)initWithOriginPinLayer:(JMXPinLayer *)anOriginPinLayer;

- (void)toggleSelected;
- (void)recalculateFrameWithPoint:(CGPoint)aPoint;
- (void)recalculateFrameWithPoint:(CGPoint)originPoint andPoint:(CGPoint)destinationPoint;
- (void)disconnect;
- (void)select;
- (void)unselect;

- (BOOL)originCanConnectTo:(JMXPinLayer *)aPinLayer;

@end
