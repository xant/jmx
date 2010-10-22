//
//  VJXBoard.h
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
#import "VJXEntityLayer.h"
#import "VJXConnectorLayer.h"
#import "VJXPinLayer.h"
#import "VJXEntityInspectorPanel.h"
#import "VJXBoardSelection.h"

#import "VJXDocument.h"

@class VJXDocument;
@class VJXPinLayer;
@class VJXConnectorLayer;

@interface VJXBoardView : NSView {
    CGPoint lastDragLocation;
    VJXEntityLayer *selectedLayer;
    VJXConnectorLayer *fakeConnectorLayer;
    NSMutableArray *selected;
    NSMutableArray *entities;
    IBOutlet VJXDocument *document;
    IBOutlet VJXEntityInspectorPanel *inspectorPanel;
}

@property (assign) VJXEntityLayer *selectedLayer;
@property (assign) VJXConnectorLayer *fakeConnectorLayer;

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification;

#pragma mark -
#pragma mark Helpers

- (void)addToBoard:(VJXEntityLayer *)theEntity;
- (CGPoint)translatePointToBoardLayer:(NSPoint)aPoint;
- (VJXEntityLayer *)entityLayerAtPoint:(CGPoint)aPoint;
- (VJXPinLayer *)pinLayerAtPoint:(CGPoint)aPoint;
- (CGFloat)maxZPosition;

@end
