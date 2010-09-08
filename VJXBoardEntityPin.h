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
    VJXBoardEntityConnector *tempConnector;
    NSMutableArray *connectors;
    NSTextField *label;
    BOOL output;
}

@property (nonatomic,retain) VJXPin *pin;
@property (nonatomic,retain) VJXBoardEntityConnector *tempConnector;
@property (nonatomic,retain) NSMutableArray *connectors;
@property (nonatomic,retain) NSTextField *label;
@property (nonatomic,assign) BOOL output;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint isOutput:(BOOL)isOutput;

- (NSPoint)pointAtCenter;
- (void)updateAllConnectorsFrames;

- (BOOL)multiple;

- (void)addConnector:(VJXBoardEntityConnector *)theConnector;

@end
