//
//  JMXBoardComponent.h
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>
#import "JMXEntity.h"
#import "JMXBoardView.h"
#import "JMXPinLayer.h"
#import "JMXGUIConstants.h"

@class JMXBoardView;

@interface JMXEntityLayer : CALayer <NSTextFieldDelegate,NSCopying,NSOutlineViewDataSource,NSOutlineViewDelegate>
{
    JMXEntity *entity;
    NSPoint lastDragLocation;
    NSTextField *label;
    NSMutableArray *outlets;
    NSMutableArray *inlets;
    JMXBoardView *board;
    BOOL selected;
@private
    CGFloat labelHeight;
}

@property (nonatomic,retain) JMXEntity *entity;
@property (nonatomic,retain) NSTextField *label;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,retain) NSMutableArray *outlets;
@property (nonatomic,retain) NSMutableArray *inlets;
@property (nonatomic, assign) JMXBoardView *board;

- (id)initWithEntity:(JMXEntity *)anEntity;
- (id)initWithEntity:(JMXEntity *)anEntity board:(JMXBoardView *)aBoard;

- (void)recalculateFrame;
- (void)reorderOutlets;
- (void)select;
- (void)unselect;
- (void)toggleSelected;
- (void)controlPin;
- (void)setupPinsLayers:(NSArray *)pins startAtPoint:(CGPoint)aPoint output:(BOOL)isOutput;
- (void)setupLayer;
- (void)updateConnectors;
- (void)moveToPointWithOffset:(NSValue *)pointValue;
- (void)removeFromBoard;

@end
