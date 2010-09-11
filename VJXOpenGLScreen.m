//
//  VJXOpenGLScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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

#import "VJXOpenGLScreen.h"


@implementation VJXOpenGLScreen

@synthesize window, view;

- (id)initWithSize:(NSSize)screenSize
{
    if (self = [super initWithSize:screenSize]) {
        NSRect frame = NSMakeRect(0, 0, size.width, size.height);
        window = [[NSWindow alloc] initWithContentRect:frame                                          
                                             styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask
                                               backing:NSBackingStoreBuffered 
                                                 defer:NO];
        view = [[VJXOpenGLView alloc] initWithFrame:[window frame]];
        [[window contentView] addSubview:view];
        [window setReleasedWhenClosed:NO];
        [window setIsVisible:YES];
    }
    return self;
    
}

- (void)dealloc
{
    [view release];
    [window release];
    [super dealloc];
}

- (void)setSize:(VJXSize *)newSize
{
    @synchronized(self) {
        if (![newSize isEqual:size]) {
            [super setSize:newSize];
            [view setSize:[newSize nsSize]];
        }
    }
}

- (void)drawFrame:(CIImage *)frame
{
    [super drawFrame:frame];
    @synchronized(self) {
        // XXX - this is a leftover from first implementation, storing the current frame
        //       in the view implementation shouldn't be necessary anymore 
        view.currentFrame = currentFrame; 
        
        // XXX - setting needsDisplay makes rendering happen in the main gui thread
        // this could lead to undesired behaviours like rendering stopping while 
        // a gui animation is in progress. Calling drawRect directly here, instead, 
        // makes rendering happen in the current thread... which is what we really want
        //[view setNeedsDisplay:YES];
        [view drawRect:NSZeroRect];
    }
}

@end
