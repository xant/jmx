//
//  JMXOpenGLScreen.h
//  JMX
//
//  Created by xant on 9/2/10.
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
#import "JMXVideoOutput.h"
#import "JMXScreenController.h"

#pragma mark -
#pragma mark JMXOpenGLView

@interface JMXOpenGLView : NSOpenGLView {
    CIImage *currentFrame;
    CIContext *ciContext;
    BOOL fullScreen;
    NSWindow *myWindow;
    NSRecursiveLock *lock;
    uint64_t lastTime;
    
#if MAC_OS_X_VERSION_10_6
    CGDisplayModeRef     savedMode;
#else
    CFDictionaryRef      savedMode;
#endif
    JMXSize *frameSize;
    BOOL needsRedraw;
    BOOL invertYCoordinates;
}

@property (atomic, retain) CIImage *currentFrame;
@property (atomic, readonly) JMXSize *frameSize;
@property (atomic, assign) BOOL needsRedraw;
@property (atomic, assign) BOOL invertYCoordinates;

- (void)setSize:(NSSize)size;
- (void)cleanup;
- (IBAction)toggleFullScreen:(id)sender;
- (void)renderFrame:(uint64_t)timeStamp;

@end

#pragma mark -
#pragma mark JMXOpenGLScreen

@interface JMXOpenGLScreen : JMXVideoOutput 
<JMXScreenControllerDelegate>
{

@private
    NSWindow *window;
    JMXOpenGLView *view;
    JMXScreenController *controller;
    BOOL fullScreen;
    JMXScript *ctx; // weak reference
    JMXOutputPin *mousePositionPin;
    NSString *lastEventType;
    uint64_t lastEventTime;
}

@property (readonly) NSWindow *window;
@property (readonly) JMXOpenGLView *view;
@property (assign) BOOL fullScreen;
@property (atomic, assign) BOOL invertYCoordinates;
@end

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXOpenGLScreen);
