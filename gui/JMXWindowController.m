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
#pragma Console Output Grabber
// bridge stdout and stderr with the NSTextView outlet (if any)
- (void)updateOutput:(NSString*)msg
{
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:msg
                                                                     attributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor]
                                                                                                            forKey:NSForegroundColorAttributeName]];
    [[outputPanel textStorage] appendAttributedString:attrString];
    [outputPanel scrollRangeToVisible:NSMakeRange([[[outputPanel textStorage] characters] count], 0)];
    [attrString release];
    [msg release];
}

- (void) consoleOutput:(id)object
{
    NSAutoreleasePool * p = [[NSAutoreleasePool alloc] init];
    char buf[65536];
    struct timeval timeout;
    fd_set rfds;
    
    fcntl(stdout_pipe[0], F_SETFL, O_NONBLOCK);
    fcntl(stderr_pipe[0], F_SETFL, O_NONBLOCK);
    if ([outputPanel isEditable])
        [outputPanel setEditable:NO];
    outputPanel.textColor = [NSColor whiteColor];
    
    for (;;) {
        timeout.tv_sec = 1;
        timeout.tv_usec = 0;
        memset(buf, 0, sizeof(buf));
        FD_ZERO(&rfds);
        FD_SET(stdout_pipe[0], &rfds);
        FD_SET(stderr_pipe[0], &rfds);
        int maxfd = ((stdout_pipe[0] > stderr_pipe[0])?stdout_pipe[0]:stderr_pipe[0]) +1;
        switch (select(maxfd, &rfds, NULL, NULL, &timeout)) {
            case -1:
            case 0:
                break;
            default:
                if (FD_ISSET(stdout_pipe[0], &rfds)) {
                    while (read(stdout_pipe[0], buf, sizeof(buf)-1) > 0) {
                        NSString *msg = [[NSString alloc] initWithCString:buf encoding:NSASCIIStringEncoding];
                        // ensure updating the view in the main thread (or this could blow up in our face)
                        [self performSelectorOnMainThread:@selector(updateOutput:)
                                               withObject:msg waitUntilDone:NO];
                    }
                }
                if (FD_ISSET(stderr_pipe[0], &rfds)) {
                    while (read(stderr_pipe[0], buf, sizeof(buf)-1) > 0) {
                        NSString *msg = [[NSString alloc] initWithCString:buf encoding:NSASCIIStringEncoding];
                        // same as above... we really need to avoid updating the textview in a different thread
                        [self performSelectorOnMainThread:@selector(updateOutput:)
                                               withObject:msg waitUntilDone:NO];
                    }
                }
        }
    }
    [p release];
}

#pragma mark -
#pragma mark NSWindowController

- (void)windowDidLoad
{
    NSLog(@"Entering viewDidLoad\n");
    JMXAppDelegate *appDelegate = [[NSApplication sharedApplication] delegate];
    if (appDelegate.batchMode) {
        [self.window close];
        self.window = nil;
    } else {
        [documentSplitView setPosition:200.0f ofDividerAtIndex:0];
        [documentSplitView adjustSubviews];
        /*
        int ret = pipe(stdout_pipe);
        NSLog(@"CHECK1: %d\n", ret);
        ret = pipe(stderr_pipe);
        NSLog(@"CHECK2: %d\n", ret);

        ret = dup2(stdout_pipe[1], fileno(stdout));
        NSLog(@"CHECK3: %d\n", ret);

        ret = dup2(stderr_pipe[1], fileno(stderr));
        NSLog(@"CHECK4: %d\n", ret);

        close(stdout_pipe[1]);
        close(stderr_pipe[1]);
        [NSThread detachNewThreadSelector:@selector(consoleOutput:) 
                                 toTarget:self withObject:nil];
         */
        [self.window becomeMainWindow];
    }
}

#pragma mark -
#pragma mark Interface Builder actions

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
    [super dealloc];
}
@end
