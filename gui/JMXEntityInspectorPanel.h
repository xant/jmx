//
//  JMXEntityInspectorPanel.h
//  JMX
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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


@class JMXEntityLayer;
@class JMXTextPanel;
@class JMXCodePanel;

@interface JMXEntityInspectorPanel : NSPanel <NSTableViewDataSource,NSTableViewDelegate,NSWindowDelegate> {
    NSMutableDictionary *dataCells;
@private
    JMXEntityLayer *entityLayer; // weak reference
    
    NSTextField *entityName;
    NSTabView *pinInspector;
    NSTableView *inputPins;
    NSTableView *outputPins;
    NSTableView *producers;
    JMXTextPanel *textPanel;
    JMXCodePanel *codePanel;
}

@property (nonatomic, assign) IBOutlet NSTextField *entityName;
@property (nonatomic, assign) IBOutlet NSTabView *pinInspector;
@property (nonatomic, assign) IBOutlet NSTableView *inputPins;
@property (nonatomic, assign) IBOutlet NSTableView *outputPins;
@property (nonatomic, assign) IBOutlet NSTableView *producers;
@property (nonatomic, assign) IBOutlet JMXTextPanel *textPanel;
@property (nonatomic, assign) IBOutlet JMXCodePanel *codePanel;

- (void)setEntity:(JMXEntityLayer *)entity;
- (void)unsetEntity:(JMXEntityLayer *)entity;

@end
