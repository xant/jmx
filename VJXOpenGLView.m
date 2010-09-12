//
//  MoviePlayerOpenGLView.m
//  MoviePlayerC
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 StrayDev.com. All rights reserved.
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

#import "VJXOpenGLView.h"

@interface VJXOpenGLView (Private)

- (void)cleanup;

@end

@implementation VJXOpenGLView

@synthesize currentFrame;

- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFADepthSize, 32,
        0
    };
    
    NSOpenGLPixelFormat* pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
    return [self initWithFrame:frameRect pixelFormat:pixelFormat];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    if (self = [super initWithFrame:frameRect pixelFormat:format]) {
        currentFrame = nil;
        ciContext = nil;
    }
    return self;
}

- (void)prepareOpenGL
{
    if (ciContext == nil) {
        [super prepareOpenGL];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        ciContext = [[CIContext contextWithCGLContext:[[self openGLContext] CGLContextObj]
                                          pixelFormat:[[self pixelFormat] CGLPixelFormatObj]
                                           colorSpace:colorSpace
                                              options:nil] retain];
        CGColorSpaceRelease(colorSpace);
        [self setNeedsDisplay:YES];
    }
}

- (void)dealloc
{
    [self cleanup];
    [super dealloc];
}

- (void)drawRect:(NSRect)rect
{
    [[self openGLContext] makeCurrentContext];

    if (CGLLockContext([[self openGLContext] CGLContextObj]) != kCGLNoError)
        NSLog(@"Could not lock CGLContext");
    
    @synchronized(self) {
        NSRect bounds = [self bounds];
        if (currentFrame != NULL) {
            CIImage *image = currentFrame;
            CGRect screenSizeRect = NSRectToCGRect(bounds);
            [ciContext drawImage:image inRect:screenSizeRect fromRect:screenSizeRect];
        }
        [[self openGLContext] flushBuffer];
        [self setNeedsDisplay:NO];
    }
    CGLUnlockContext([[self openGLContext] CGLContextObj]);

}

// Called by Cocoa when the view's visible rectangle or bounds change.
- (void)reshape
{
    @synchronized(self) {
        NSRect bounds = [self frame];

        GLfloat minX, minY, maxX, maxY;
        minX = NSMinX(bounds);
        minY = NSMinY(bounds);
        maxX = NSMaxX(bounds);
        maxY = NSMaxY(bounds);
        [[self openGLContext] makeCurrentContext];
        
        if (CGLLockContext([[self openGLContext] CGLContextObj]) != kCGLNoError)
            NSLog(@"Could not lock CGLContext");
        
        glViewport(0, 0, bounds.size.width, bounds.size.height);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(minX, maxX, minY, maxY, -1.0, 1.0);
        glDisable(GL_DITHER);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_BLEND);
        glDisable(GL_STENCIL_TEST);
        glDisable(GL_FOG);
        glDisable(GL_DEPTH_TEST);
        glPixelZoom(1.0, 1.0);
        glClearColor(0.0, 0.0, 0.0, 1.0);
        glClear(GL_COLOR_BUFFER_BIT);
        CGLUnlockContext([[self openGLContext] CGLContextObj]);
    }
}

- (void)cleanup
{
    if (ciContext) {
        [ciContext release];
        ciContext = nil;
    }

    if (lock) {
        [lock release];
        lock = nil;
    }
    self.currentFrame = nil;
}

- (void)setSize:(NSSize)size
{
    @synchronized(self) {
        NSRect actualRect = [[self window ] frame];
        // XXX - we actually don't allow setting a 0-size (for neither width nor height)
        if (size.width && size.height &&
            (size.width != actualRect.size.width ||
            size.height != actualRect.size.height))
        {
            NSRect newRect = NSMakeRect(0, 0, size.width, size.height);
            [self setFrame:newRect];
            newRect.origin.x = actualRect.origin.x;
            newRect.origin.y = actualRect.origin.y;
            [[self window] setFrame:newRect display:NO];
            [[self window] setMovable:YES]; // XXX - this shouldn't be necessary
        }
    }
}

@end
