//
//  VJXBoardComponentConnector.h
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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "VJXPinLayer.h"
#import "VJXBoardView.h"
#import "VJXGUIConstants.h"

@class VJXPinLayer;
@class VJXBoardView;

enum Direction {
    kSouthEastDirection,
    kNorthEastDirection,
    kSouthWestDirection,
    kNorthWestDirection
};

@interface VJXConnectorLayer : CALayer {
    BOOL selected;
    VJXBoardView *boardView;
    CGPoint initialPosition;
    VJXPinLayer *originPinLayer;
    VJXPinLayer *destinationPinLayer;
    NSUInteger direction;
}

@property (assign) BOOL selected;
@property (assign) VJXBoardView *boardView;
@property (assign) CGPoint initialPosition;
@property (assign) NSUInteger direction;

// make this weak references otherwise pins will be overretained an never released
// the following two properties must be defined as atomic because can be accessed
// by differnt threads (since pins can be disconnected in any moment)
@property (assign) VJXPinLayer *originPinLayer;
@property (assign) VJXPinLayer *destinationPinLayer;

- (id)initWithOriginPinLayer:(VJXPinLayer *)anOriginPinLayer;

- (void)toggleSelected;
- (void)recalculateFrameWithPoint:(CGPoint)aPoint;
- (void)recalculateFrameWithPoint:(CGPoint)originPoint andPoint:(CGPoint)destinationPoint;
- (void)disconnect;
@end
