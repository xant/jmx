//
//  VJXEntityInspectorPanel.h
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VJXBoardEntity;

@interface VJXEntityInspectorPanel : NSView <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTextField *entityName;
    IBOutlet NSTabView *pinInspector;
    IBOutlet NSTableView *inputPins;
    IBOutlet NSTableView *outputPins;
    IBOutlet NSTableView *producers;
	IBOutlet NSOutlineView *pinsProperties;
@private 
    VJXBoardEntity *entityView; // weak reference
}

- (void)setEntity:(VJXBoardEntity *)entity;
- (void)unsetEntity:(VJXBoardEntity *)entity;

- (void)anEntityWasSelected:(NSNotification *)aNotification;

@end
