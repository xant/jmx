//
//  JMXBoardViewController.h
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXConnectorLayer.h"
#import "JMXPinLayer.h"

@class JMXConnectorLayer;
@class JMXPinLayer;
@class JMXDocument;
@class JMXEntitiesController;
@class JMXScriptEntity;

@interface JMXBoardViewController : NSViewController <NSTextFieldDelegate> {
    JMXEntityLayer *selectedLayer;
	JMXConnectorLayer *selectedConnectorLayer;
	JMXConnectorLayer *fakeConnectorLayer;
	JMXPinLayer *hoveredPinLayer;
    NSMutableArray *selected;
    NSMutableArray *entities;
    JMXEntitiesController *entitiesController;
    NSPoint lastDragLocation;
    JMXScriptEntity *scriptController;
    IBOutlet NSTextField *jsInput;
}

@property (nonatomic, assign) JMXEntityLayer *selectedLayer;
@property (nonatomic, assign) JMXConnectorLayer *selectedConnectorLayer;
@property (nonatomic, retain) NSMutableArray *entities;
@property (nonatomic, readonly) JMXEntitiesController *entitiesController;
#pragma mark -
#pragma mark IBActions

- (IBAction)removeSelectedEntity:(id)sender;

@end
