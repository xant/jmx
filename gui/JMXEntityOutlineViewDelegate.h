//
//  JMXEntityOutlineView.h
//  JMX
//
//  Created by Igor Sutton on 10/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JMXEntity;
@class JMXEntityProducerTableViewDelegate;

@interface JMXEntityOutlineViewDelegate : NSObject <NSOutlineViewDelegate, NSOutlineViewDataSource> {
    JMXEntity *entity;
    NSMutableDictionary *virtualOutputPins;
    NSMutableArray *virtualOutputPinNames;
    NSMutableDictionary *dataCells;
    NSOutlineView *entityOutlineView;
    NSTableView *entityProducerTableView;
    JMXEntityProducerTableViewDelegate *entityProducerTableViewDelegate; // Is also dataSource.
}

@property (nonatomic, assign) JMXEntity *entity;
@property (nonatomic, assign) IBOutlet NSOutlineView *entityOutlineView;
@property (nonatomic, assign) IBOutlet NSTableView *entityProducerTableView;
@property (nonatomic, assign) IBOutlet JMXEntityProducerTableViewDelegate *entityProducerTableViewDelegate;

- (void)setUpPins;

@end
