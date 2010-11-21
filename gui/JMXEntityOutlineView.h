//
//  JMXEntityOutlineView.h
//  JMX
//
//  Created by Igor Sutton on 10/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"


@interface JMXEntityOutlineView : NSOutlineView <NSOutlineViewDelegate, NSOutlineViewDataSource> {

    NSViewController *viewController;

    JMXEntity *entity;

    NSMutableDictionary *virtualOutputPins;
    NSMutableArray *virtualOutputPinNames;
    NSMutableDictionary *dataCells;
}

@property (assign) IBOutlet JMXEntity *entity;
@property (nonatomic, assign) IBOutlet NSViewController *viewController;

- (void)setUpPins;

@end
