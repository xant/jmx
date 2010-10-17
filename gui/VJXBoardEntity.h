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
#import "VJXEntity.h"
#import "VJXBoard.h"

#define ENTITY_LABEL_PADDING 12.0
#define ENTITY_PIN_MINSPACING 1.5
#define ENTITY_FRAME_WIDTH 220.0
#define ENTITY_PIN_HEIGHT 11.0
#define ENTITY_PIN_LEFT_PADDING 6.0

@class VJXBoard;

@interface VJXBoardEntity : NSView <NSTextFieldDelegate,NSCopying,NSOutlineViewDataSource,NSOutlineViewDelegate>
{
    VJXEntity *entity;
    NSPoint lastDragLocation;
    NSTextField *label;
    NSMutableArray *outlets;

    VJXBoard *board;
    
    BOOL selected;
}

@property (nonatomic,retain) VJXEntity *entity;
@property (nonatomic,retain) NSTextField *label;
@property (nonatomic,assign) BOOL selected;
@property (nonatomic,retain) NSMutableArray *outlets;
@property (nonatomic, assign) VJXBoard *board;

- (id)initWithEntity:(VJXEntity *)anEntity;
- (id)initWithEntity:(VJXEntity *)anEntity board:(VJXBoard *)aBoard;

- (void)toggleSelected;
- (BOOL)inRect:(NSRect)rect;
- (void)unselect;

- (void)shiftOffsetToLocation:(NSPoint)aLocation;

- (void)setNeedsDisplay;

- (void)controlPin;

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item;

@end
