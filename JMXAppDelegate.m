//
//  JMXAppDelegate.m
//  JMX
//
//  Created by Igor Sutton on 8/24/10.
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

#import "JMXApplication.h"
#import "JMXContext.h"
#import "JMXGlobals.h"
#import "JMXLibraryTableView.h"
#import <JMXScriptFile.h>
#import <QTKit/QTKit.h>

@implementation JMXAppDelegate

@synthesize window, consoleView, libraryTableView;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    [super applicationWillFinishLaunching:notification];
    [libraryTableView reloadData];    
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    [super applicationDidFinishLaunching:notification];
    if (self.batchMode) {
        [window setIsVisible:NO];
    }
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}


- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (void)updateOutput:(NSString*)msg
{
    NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n", msg]
                                                                     attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                 [NSColor whiteColor],
                                                                                 NSForegroundColorAttributeName,
                                                                                 [NSFont fontWithName:@"Courier" size:12],
                                                                                 NSFontAttributeName,
                                                                                 nil]];
    [[consoleView textStorage] appendAttributedString:attrString];
    [consoleView scrollRangeToVisible:NSMakeRange([[[consoleView textStorage] characters] count], 0)];
    [attrString release];
}


- (void)logMessage:(NSString *)message, ...
{
    va_list args;
    va_start(args, message);
    if ([window isVisible]) {
        //NSString *msg = [[NSString alloc] initWithCString:buf encoding:NSASCIIStringEncoding];

        NSString *msg = [[[NSString alloc] initWithFormat:message arguments:args] autorelease];
        // same as above... we really need to avoid updating the textview in a different thread
        [self performSelectorOnMainThread:@selector(updateOutput:)
                               withObject:msg waitUntilDone:NO];
    } else if (message) {
        [super logMessage:message args:args];
    }
    va_end(args);
}

@end
