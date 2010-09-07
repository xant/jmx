//
//  VJXBoardComponentConnector.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXBoardEntityPin.h"

@class VJXBoardEntityPin;

enum Direction {
    kSouthEastDirection,
    kNorthEastDirection,
    kSouthWestDirection,
    kNorthWestDirection
};

@interface VJXBoardEntityConnector : NSView {
    VJXBoardEntityPin *origin;
    VJXBoardEntityPin *destination;
    NSUInteger direction;
}

@property (assign) NSUInteger direction;
@property (nonatomic,retain) VJXBoardEntityPin *origin;
@property (nonatomic,retain) VJXBoardEntityPin *destination;

- (void)recalculateFrame;

@end
