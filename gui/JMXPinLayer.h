//
//  JMXBoardEntityPin.h
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
#import "JMXConnectorLayer.h"
#import "JMXPin.h"
#import "JMXOutletLayer.h"
#import "JMXGUIConstants.h"

@class JMXConnectorLayer;
@class JMXOutletLayer;
@class JMXEntityInspector;

@interface JMXPinLayer : CALayer
{
    BOOL selected;
@protected
    JMXPin *pin;
@private
    JMXConnectorLayer *tempConnector;
    JMXEntityInspector *inspector;
    JMXOutletLayer *outlet;
    NSMutableArray *connectors;
}

@property (nonatomic,assign) BOOL selected;
@property (nonatomic,readonly) JMXPin *pin;

- (id)initWithPin:(JMXPin *)thePin andPoint:(NSPoint)thePoint outlet:(JMXOutletLayer *)anOutlet;
- (CGPoint)pointAtCenter;
- (void)updateAllConnectorsFrames;
- (BOOL)multiple;
- (void)addConnector:(JMXConnectorLayer *)theConnector;
- (void)removeConnector:(JMXConnectorLayer *)theConnector;
- (void)removeAllConnectors;
- (BOOL)isConnected;
- (void)toggleSelected;
- (void)setupLayer;

- (void)focus;
- (void)unfocus;

@end
