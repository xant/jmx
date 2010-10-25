//
//  VJXEntityOutlineView.h
//  VeeJay
//
//  Created by Igor Sutton on 10/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"


@interface VJXEntityOutlineView : NSOutlineView <NSOutlineViewDelegate, NSOutlineViewDataSource> {
    VJXEntity *entity;

    NSMutableDictionary *virtualOutputPins;
    NSMutableArray *virtualOutputPinNames;
    NSMutableDictionary *dataCells;
}

@property (assign) VJXEntity *entity;

- (void)setUpPins;

- (IBAction)commitChange:(id)sender;

@end
