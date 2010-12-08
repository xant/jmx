//
//  JMXWindowController.h
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntityInspectorPanel.h"

@interface JMXWindowController : NSWindowController {
	NSView *libraryView;	
	NSSplitView *documentSplitView;
	NSViewController *boardViewController;
    IBOutlet NSPanel *inspectorPanel;
}

@property (nonatomic, assign) IBOutlet NSSplitView *documentSplitView;
@property (nonatomic, retain) IBOutlet NSViewController *boardViewController;

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)toggleInspector:(id)sender;
- (IBAction)toggleLibrary:(id)sender;

@end
