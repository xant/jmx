//
//  JMXWindowController.m
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXWindowController.h"
#import "JMXBoardViewController.h"
#import "JMXAppDelegate.h"
#import "JMXEntitiesController.h"

@implementation JMXWindowController

@synthesize documentSplitView;
@synthesize boardViewController;
@synthesize libraryView;

#pragma mark -
#pragma mark NSWindowController

- (void)windowWillLoad
{
    [super windowWillLoad];
}

- (void)windowDidLoad
{
    NSLog(@"Entering viewDidLoad\n");
    JMXAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    if (appDelegate.batchMode) {
        [self.window close];
        //self.window = nil;
    } else {
        [documentSplitView setPosition:200.0f ofDividerAtIndex:0];
        [documentSplitView adjustSubviews];

        [self.window becomeMainWindow];
    }
}

#pragma mark -
#pragma mark Interface Builder actions

- (IBAction)toggleDOMBrowser:(id)sender
{
	if ([domBrowser isVisible]) {
        [domBrowser close];
        if ([sender isKindOfClass:[NSMenuItem class]])
            [(NSMenuItem *)sender setTitle:@"Show DOM Browser"];
	}
	else {
        [domBrowser setIsVisible:YES];
        [domBrowser makeKeyAndOrderFront:sender];
        if ([sender isKindOfClass:[NSMenuItem class]])
            [(NSMenuItem *)sender setTitle:@"Hide DOM Browser"];
	}
}

- (IBAction)toggleInspector:(id)sender
{
	if ([inspectorPanel isVisible]) {
        [inspectorPanel close];
        if ([sender isKindOfClass:[NSMenuItem class]])
            [(NSMenuItem *)sender setTitle:@"Show Inspector"];
	}
	else {
        [inspectorPanel setIsVisible:YES];
        [inspectorPanel makeKeyAndOrderFront:sender];
        if ([sender isKindOfClass:[NSMenuItem class]])
            [(NSMenuItem *)sender setTitle:@"Hide Inspector"];
	}
}

- (IBAction)toggleLibrary:(id)sender
{
	NSMenuItem *menuItem = (NSMenuItem *)sender;
	if ([documentSplitView isSubviewCollapsed:libraryView]) {
		[libraryView setHidden:NO];
		[documentSplitView adjustSubviews];
		[documentSplitView setPosition:200.0f ofDividerAtIndex:0];
		[menuItem setTitle:@"Hide Library"];
	}
	else {
		[libraryView setHidden:YES];
		[documentSplitView adjustSubviews];
		[menuItem setTitle:@"Show Library"];
	}
	
}

- (IBAction)showJavascriptExamples:(id)sender
{
    //NSURL *url = [[[NSBundle mainBundle] sharedSupportURL] URLByAppendingPathComponent:@"javascript_examples"];
    
    NSURL *url = [[NSURL fileURLWithPath:[[NSBundle mainBundle] sharedSupportPath]]
                  URLByAppendingPathComponent:@"javascript_examples"];

    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:[NSArray arrayWithObject:url]];
}
#pragma mark -

- (void)setBoardViewController:(NSViewController *)vc
{
	if (boardViewController != vc)
		[boardViewController release];
	
	boardViewController = [vc retain];

}


// if the main window is being dragged we need to remove selection
// for some weird reason if there is a selection , the selected layer will disappear
// from the board (even if still present and added as sublayer, it seems it's not drawn anyway ...
// even if forcing calls to '- (void)drawInContext:'
- (void)mouseDragged:(NSEvent *)theEvent
{
    [((JMXBoardViewController *)boardViewController).entitiesController unselectAll];
    [super mouseDragged:theEvent];
}

- (void)dealloc
{
    [inspectorPanel release];
    [outputPanel release];
    [domBrowser release];
    [super dealloc];
}
@end
