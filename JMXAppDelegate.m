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
#import "JMXJavascriptFile.h"

@implementation JMXAppDelegate

@synthesize window, layersTableView;

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
    [sharedContext registerClass:[JMXJavascriptFile class]];
	NSLog(@"Registered %i entities", [[sharedContext registeredClasses] count]);
}

- (void)awakeFromNib
{
    [layersTableView registerForDraggedTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"]];
}


- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

@end
