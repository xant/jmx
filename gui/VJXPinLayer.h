//
//  VJXBoardEntityPin.h
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
#import "VJXConnectorLayer.h"
#import "VJXPin.h"
#import "VJXEntityInspector.h"
#import "VJXOutletLayer.h"
#import "VJXGUIConstants.h"

@class VJXConnectorLayer;
@class VJXOutletLayer;

@interface VJXPinLayer : CALayer
{
    BOOL selected;
@protected
    VJXPin *pin;
    NSMutableArray *connectors;
@private
    VJXConnectorLayer *tempConnector;
    VJXEntityInspector *inspector;
    VJXOutletLayer *outlet;
}

@property (nonatomic,assign) BOOL selected;
@property (nonatomic,readonly) VJXPin *pin;
@property (nonatomic,readonly) NSArray *connectors;

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint outlet:(VJXOutletLayer *)anOutlet;
- (CGPoint)pointAtCenter;
- (void)updateAllConnectorsFrames;
- (BOOL)multiple;
- (void)addConnector:(VJXConnectorLayer *)theConnector;
- (void)removeConnector:(VJXConnectorLayer *)theConnector;
- (void)removeAllConnectors;
- (BOOL)isConnected;
- (void)toggleSelected;
- (void)setupLayer;

- (void)focus;
- (void)unfocus;

@end
