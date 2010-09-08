//
//  VJXBoardComponentOutlet.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXBoardEntityConnector.h"
#import "VJXPin.h"

@class VJXBoardEntityConnector;

@interface VJXBoardEntityPin : NSView
{
    VJXPin *pin;
    VJXBoardEntityConnector *connector;
}

@property (nonatomic,retain) VJXPin *pin;
@property (nonatomic,retain) VJXBoardEntityConnector *connector;

- (NSPoint)pointAtCenter;
- (void)updateAllConnectorsFrames;

@end
