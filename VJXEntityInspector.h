//
//  VJXEntityInspector.h
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXBoardEntity.h"
#import "VJXEntityInspectorPanel.h"

@interface VJXEntityInspector : NSObject < NSTableViewDataSource > {
@private 
    VJXBoardEntity *entity; // weak reference
    VJXEntityInspectorPanel *panel;
    NSTableView *inputPins;
    NSTableView *outputPins;
}

@property (assign)VJXBoardEntity *entity; // we don't want to retain the entity
@property (assign)VJXEntityInspectorPanel *panel; // we don't want to retain the entity

+ (void)setEntity:(VJXBoardEntity *)entity;
+ (void)setPanel:(VJXEntityInspectorPanel *)aPanel;

@end
