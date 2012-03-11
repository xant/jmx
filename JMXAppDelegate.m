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

#import "JMXAppDelegate.h"
#import "JMXContext.h"
#import "JMXVideoMixer.h"
#import "JMXQtMovieEntity.h"
#import "JMXOpenGLScreen.h"
#import "JMXImageEntity.h"
#import "JMXQtVideoCaptureEntity.h"
#import "JMXAudioFileEntity.h"
#import "JMXCoreAudioOutput.h"
#import "JMXQtAudioCaptureEntity.h"
#import "JMXAudioMixer.h"
#import "JMXAudioSpectrumAnalyzer.h"
#import "JMXCoreImageFilter.h"
#import "JMXTextEntity.h"
#import "JMXScriptFile.h"
#import "JMXScriptLive.h"
#import "JMXPhidgetEncoderEntity.h"
#import "JMXGlobals.h"
#import "JMXLibraryTableView.h"
#import "JMXHIDInputEntity.h"
#import "CIAlphaBlend.h"
#import "CIAdditiveBlur.h"

@implementation JMXAppDelegate

@synthesize window, batchMode, consoleView, libraryTableView;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	JMXContext *sharedContext = [JMXContext sharedContext];
	[sharedContext registerClass:[JMXVideoMixer class]];
	[sharedContext registerClass:[JMXImageEntity class]];
	[sharedContext registerClass:[JMXOpenGLScreen class]];
	[sharedContext registerClass:[JMXQtVideoCaptureEntity class]];
	[sharedContext registerClass:[JMXQtMovieEntity class]];
	[sharedContext registerClass:[JMXCoreAudioOutput class]];
	[sharedContext registerClass:[JMXQtAudioCaptureEntity class]];
	[sharedContext registerClass:[JMXAudioFileEntity class]];
	[sharedContext registerClass:[JMXAudioMixer class]];
    [sharedContext registerClass:[JMXAudioSpectrumAnalyzer class]];
    [sharedContext registerClass:[JMXCoreImageFilter class]];
	[sharedContext registerClass:[JMXTextEntity class]];
    [sharedContext registerClass:[JMXScriptFile class]];
    [sharedContext registerClass:[JMXScriptLive class]];
    [sharedContext registerClass:[JMXHIDInputEntity class]];
    [CIAlphaBlend class]; // trigger initialize to have the filter registered and available in the videomixer
    [CIAdditiveBlur class];
    if (CPhidgetEncoder_create != NULL) {
        // XXX - exception case for weakly linked Phidget library
        //       if it's not available at runtime we don't want to register the phidget-related entities
        //       or the application will crash when the user tries accessing them
        [sharedContext registerClass:[JMXPhidgetEncoderEntity class]];
    }
	INFO("Registered %ul entities", (unsigned int)[[sharedContext registeredClasses] count]);
    [libraryTableView reloadData];
    
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

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    JMXScriptFile *file = [[JMXScriptFile alloc] init];
    file.active = YES;
    batchMode = YES;
    file.path = filename;
    [window setIsVisible:NO];
    return YES;
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
        NSLogv(message, args);
    }
    va_end(args);
}

@end
