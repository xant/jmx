//
//  VJXEntityInspectorPanel.h
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class VJXEntityLayer;

@interface VJXEntityInspectorPanel : NSView <NSTableViewDataSource,NSTableViewDelegate> {
    IBOutlet NSTextField *entityName;
    IBOutlet NSTabView *pinInspector;
    IBOutlet NSTableView *inputPins;
    IBOutlet NSTableView *outputPins;
    IBOutlet NSTableView *producers;
	IBOutlet NSOutlineView *pinsProperties;
@private
    VJXEntityLayer *entityView; // weak reference
}

- (void)setEntity:(VJXEntityLayer *)entity;
- (void)unsetEntity:(VJXEntityLayer *)entity;

- (void)anEntityWasSelected:(NSNotification *)aNotification;

@end
