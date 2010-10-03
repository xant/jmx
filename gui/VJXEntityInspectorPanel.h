//
//  VJXEntityInspectorPanel.h
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VJXBoardEntity;

@interface VJXEntityInspectorPanel : NSPanel <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTextField *entityName;
    IBOutlet NSTabView *pinInspector;
    IBOutlet NSTableView *inputPins;
    IBOutlet NSTableView *outputPins;
    IBOutlet NSTableView *producers;
@private 
    VJXBoardEntity *entityView; // weak reference
}

@property (readonly) NSTextField *entityName;
@property (readonly) NSTabView *pinInspector;
@property (readonly) NSTableView *inputPins;
@property (readonly) NSTableView *outputPins;
@property (readonly) NSTableView *producers;

@property (assign) VJXBoardEntity *entityView; // we don't want to retain the entity
//@property (assign) VJXEntityInspectorPanel *panel; // we don't want to retain the entity

- (void)setEntity:(VJXBoardEntity *)entity;
- (void)unsetEntity:(VJXBoardEntity *)entity;

- (void)anEntityWasSelected:(NSNotification *)aNotification;

@end
