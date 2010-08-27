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

@interface VJXBoardEntityConnector : NSView {
    NSUInteger direction;
    VJXBoardEntityPin *origin;
    VJXBoardEntityPin *destination;
}

@property (assign) NSUInteger direction;
@property (nonatomic,retain) VJXBoardEntityPin *origin;
@property (nonatomic,retain) VJXBoardEntityPin *destination;

@end
