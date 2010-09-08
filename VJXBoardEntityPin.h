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
@protected
    VJXPin *pin;
    NSMutableArray *connectors;
@private
    VJXBoardEntityConnector *tempConnector;
}

@property (nonatomic,readonly) VJXPin *pin;
@property (nonatomic,readonly) NSArray *connectors;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint;
- (NSPoint)pointAtCenter;
- (void)updateAllConnectorsFrames;
- (BOOL)multiple;
- (void)addConnector:(VJXBoardEntityConnector *)theConnector;
- (void)removeConnector:(VJXBoardEntityConnector *)theConnector;
- (void)removeAllConnectors;
- (BOOL)isConnected;
@end
