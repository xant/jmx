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
- (void)reShape;

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
        needsReShape = YES;
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
    NSRect bounds = [self bounds];

    if (CGLLockContext([[self openGLContext] CGLContextObj]) != kCGLNoError) {
        NSLog(@"Could not lock CGLContext");
    }

    [[self openGLContext] makeCurrentContext];

    if (needsReShape) {
        [self reShape];
        needsReShape = NO;
    }
    @synchronized(self) {
        if (currentFrame != NULL) {
            CIImage *image = currentFrame;
            CGRect imageRect = [image extent];
            CGRect inRect = NSRectToCGRect(bounds);
            [ciContext drawImage:image inRect:inRect fromRect:imageRect];
        }

        [[self openGLContext] flushBuffer];
        [self setNeedsDisplay:NO];

    }
    CGLUnlockContext([[self openGLContext] CGLContextObj]);

}

- (void)reShape
{
    NSLog(@"reShape:");
    NSRect bounds = [self bounds];

    GLfloat minX, minY, maxX, maxY;
    minX = NSMinX(bounds);
    minY = NSMinY(bounds);
    maxX = NSMaxX(bounds);
    maxY = NSMaxY(bounds);
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
    glClearColor(0.0, 0.0, 0.0, 0.0);
    glClear(GL_COLOR_BUFFER_BIT);
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
}

@end
