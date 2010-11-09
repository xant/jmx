//
//  JMXBoard.h
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
//  You should have Îreceived a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntityLayer.h"
#import "JMXConnectorLayer.h"
#import "JMXPinLayer.h"
#import "JMXEntityInspectorPanel.h"
#import "JMXBoardSelection.h"

#import "JMXDocument.h"

@class JMXDocument;
@class JMXPinLayer;
@class JMXConnectorLayer;

@interface JMXBoardView : NSView {
    CGPoint lastDragLocation;
    JMXEntityLayer *selectedLayer;
	JMXConnectorLayer *selectedConnectorLayer;
    JMXPinLayer *hoveredPinLayer;
    JMXConnectorLayer *fakeConnectorLayer;
    NSMutableArray *selected;
    NSMutableArray *entities;
    IBOutlet JMXDocument *document;
    IBOutlet JMXEntityInspectorPanel *inspectorPanel;
}

@property (nonatomic,assign) JMXEntityLayer *selectedLayer;
@property (nonatomic,assign) JMXConnectorLayer *selectedConnectorLayer;
#pragma mark -
#pragma mark IBActions

- (IBAction)removeSelected:(id)sender;

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification;

#pragma mark -
#pragma mark Helpers

- (void)addToBoard:(JMXEntityLayer *)theEntity;
- (CGPoint)translatePointToBoardLayer:(NSPoint)aPoint;
- (JMXEntityLayer *)entityLayerAtPoint:(NSPoint)aPoint;
- (JMXPinLayer *)pinLayerAtPoint:(NSPoint)aPoint;
- (JMXConnectorLayer *)connectorLayerAtPoint:(NSPoint)aPoint;
- (CGFloat)maxZPosition;

@end
