//
//  JMXEntityInspectorPanel.h
//  JMX
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class JMXEntityLayer;
@class JMXTextPanel;

@interface JMXEntityInspectorPanel : NSPanel <NSTableViewDataSource,NSTableViewDelegate,NSWindowDelegate> {
    IBOutlet NSTextField *entityName;
    IBOutlet NSTabView *pinInspector;
    IBOutlet NSTableView *inputPins;
    IBOutlet NSTableView *outputPins;
    IBOutlet NSTableView *producers;
    IBOutlet JMXTextPanel *textPanel;
    NSMutableDictionary *dataCells;
@private
    JMXEntityLayer *entityLayer; // weak reference
}

- (void)setEntity:(JMXEntityLayer *)entity;
- (void)unsetEntity:(JMXEntityLayer *)entity;

@end
