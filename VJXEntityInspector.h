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

@interface VJXEntityInspector : NSObject < NSTableViewDataSource,NSTableViewDelegate > {
@private 
    VJXBoardEntity *entityView; // weak reference
    VJXEntityInspectorPanel *panel;
    NSTableView *inputPins;
    NSTableView *outputPins;
    NSTableView *producers;
}

@property (assign)VJXBoardEntity *entityView; // we don't want to retain the entity
@property (assign)VJXEntityInspectorPanel *panel; // we don't want to retain the entity

+ (void)setEntity:(VJXBoardEntity *)entity;
+ (void)unsetEntity:(VJXBoardEntity *)entity;
+ (void)setPanel:(VJXEntityInspectorPanel *)aPanel;

@end
