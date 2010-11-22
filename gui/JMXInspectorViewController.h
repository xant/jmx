//
//  JMXInspectorViewController.h
//  JMX
//
//  Created by Igor Sutton on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntityOutlineViewDelegate.h"

@class JMXEntityProducerTableViewDelegate;
@class JMXEntityOutlineViewDelegate;

@interface JMXInspectorViewController : NSViewController {
    NSObjectController *entityController;
    NSOutlineView *entityOutlineView;
    NSTableView *entityProducerTableView;
    JMXEntityOutlineViewDelegate *entityOutlineViewDelegate;
    JMXEntityProducerTableViewDelegate *entityProducerTableViewDelegate;
}

@property (nonatomic, retain) IBOutlet NSObjectController *entityController;
@property (nonatomic, retain) IBOutlet NSOutlineView *entityOutlineView;
@property (nonatomic, retain) IBOutlet NSTableView *entityProducerTableView;
@property (nonatomic, retain) IBOutlet JMXEntityOutlineViewDelegate *entityOutlineViewDelegate;
@property (nonatomic, retain) IBOutlet JMXEntityProducerTableViewDelegate *entityProducerTableViewDelegate;

@end
