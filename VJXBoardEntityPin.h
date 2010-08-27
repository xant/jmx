//
//  VJXBoardComponentOutlet.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXBoardEntityConnector.h"

@class VJXBoardEntityConnector;

@interface VJXBoardEntityPin : NSView {
    VJXBoardEntityConnector *connector;
}

@property (nonatomic,retain) VJXBoardEntityConnector *connector;

@end
