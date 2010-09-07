//
//  VJXBoardComponent.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"

@interface VJXBoardEntity : NSView
{
    VJXEntity *entity;
    NSPoint lastDragLocation;
}

@property (nonatomic,retain) VJXEntity *entity;

- (id)initWithEntity:(VJXEntity *)theEntity;

@end
