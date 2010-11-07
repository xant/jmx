//
//  VeeJayAppDelegate.m
//  VJX
//
//  Created by Igor Sutton on 8/24/10.
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

#import "VeeJayAppDelegate.h"
#import "VJXContext.h"
#import "VJXVideoMixer.h"
#import "VJXQtMovieEntity.h"
#import "VJXOpenGLScreen.h"
#import "VJXImageEntity.h"
#import "VJXQtVideoCaptureEntity.h"
#import "VJXAudioFileEntity.h"
#import "VJXCoreAudioOutput.h"
#import "VJXQtAudioCaptureEntity.h"
#import "VJXAudioMixer.h"
#import "VJXAudioSpectrumAnalyzer.h"
#import "VJXCoreImageFilter.h"
#import "VJXTextEntity.h"
#import "VJXJavascriptFile.h"

@implementation VeeJayAppDelegate

@synthesize window, layersTableView;

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	VJXContext *sharedContext = [VJXContext sharedContext];
	[sharedContext registerClass:[VJXVideoMixer class]];
	[sharedContext registerClass:[VJXImageEntity class]];
	[sharedContext registerClass:[VJXOpenGLScreen class]];
	[sharedContext registerClass:[VJXQtVideoCaptureEntity class]];
	[sharedContext registerClass:[VJXQtMovieEntity class]];
	[sharedContext registerClass:[VJXCoreAudioOutput class]];
	[sharedContext registerClass:[VJXQtAudioCaptureEntity class]];
	[sharedContext registerClass:[VJXAudioFileEntity class]];
	[sharedContext registerClass:[VJXAudioMixer class]];
    [sharedContext registerClass:[VJXAudioSpectrumAnalyzer class]];
    [sharedContext registerClass:[VJXCoreImageFilter class]];
	[sharedContext registerClass:[VJXTextEntity class]];
    [sharedContext registerClass:[VJXJavascriptFile class]];
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
