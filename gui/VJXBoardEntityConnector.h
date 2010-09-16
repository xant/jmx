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
#import "VJXBoardEntityPin.h"
#import "VJXBoard.h"

@class VJXBoardEntityPin;
@class VJXBoard;

enum Direction {
    kSouthEastDirection,
    kNorthEastDirection,
    kSouthWestDirection,
    kNorthWestDirection
};

@interface VJXBoardEntityConnector : NSView {
    BOOL selected;
    VJXBoard *board;
    VJXBoardEntityPin *origin;
    VJXBoardEntityPin *destination;
    NSUInteger direction;
}

@property (assign) BOOL selected;
@property (assign) VJXBoard *board;
@property (assign) NSUInteger direction;
// make this weak references otherwise pins will be overretained an never released
@property (nonatomic,assign) VJXBoardEntityPin *origin;
@property (nonatomic,assign) VJXBoardEntityPin *destination;

- (void)recalculateFrame;
- (void)toggleSelected;

@end
