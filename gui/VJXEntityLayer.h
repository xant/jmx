//
//  VJXBoardComponent.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "VJXEntity.h"
#import "VJXBoardView.h"
#import "VJXPinLayer.h"
#import "VJXGUIConstants.h"

@class VJXBoardView;

// @interface VJXBoardEntity : NSView <NSTextFieldDelegate,NSCopying,NSOutlineViewDataSource,NSOutlineViewDelegate>
@interface VJXEntityLayer : CALayer <NSTextFieldDelegate,NSCopying,NSOutlineViewDataSource,NSOutlineViewDelegate>
{
    VJXEntity *entity;
    NSPoint lastDragLocation;
    NSTextField *label;
    NSMutableArray *outlets;
    NSMutableArray *inlets;
    VJXBoardView *board;
    BOOL selected;
@private
    CGFloat labelHeight;
}

@property (nonatomic,retain) VJXEntity *entity;
@property (nonatomic,retain) NSTextField *label;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,retain) NSMutableArray *outlets;
@property (nonatomic,retain) NSMutableArray *inlets;
@property (nonatomic, assign) VJXBoardView *board;

- (id)initWithEntity:(VJXEntity *)anEntity;
- (id)initWithEntity:(VJXEntity *)anEntity board:(VJXBoardView *)aBoard;

- (VJXPin *)inputPinWithName:(NSString *)aPinName;
- (VJXPin *)outputPinWithName:(NSString *)aPinName;

- (void)recalculateFrame;
- (void)reorderOutlets;
- (void)select;
- (void)unselect;
- (void)toggleSelected;
- (void)controlPin;
- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;
- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item;
- (void)setupPinsLayers:(NSArray *)pins startAtPoint:(CGPoint)aPoint output:(BOOL)isOutput;
- (void)setupLayer;

@end
