//
//  VJXOpenGLScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXOpenGLScreen.h"


@implementation VJXOpenGLScreen

@synthesize window, view;

- (id)initWithSize:(NSSize)screenSize
{
    if (self = [super initWithSize:screenSize]) {
        NSRect frame = { { 0, 0 }, { size.width, size.height } };
        window = [[NSWindow alloc] initWithContentRect:frame                                          
                                                   styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask
                                                     backing:NSBackingStoreBuffered defer:NO];
        view = [[VJXOpenGLView alloc] initWithFrame:[window frame]];
        [[window contentView] addSubview:view];
        [window setIsVisible:YES];
    }
    return self;
    
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
