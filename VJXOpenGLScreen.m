//
//  VJXOpenGLScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXOpenGLScreen.h"


@implementation VJXOpenGLScreen

- (id)initWithSize:(NSSize)screenSize
{
    if (self = [super initWithSize:screenSize]) {
        NSRect frame = { { 0, 0 }, { size.width, size.height } };
        screenWindow = [[NSWindow alloc] initWithContentRect:frame                                          
                                                   styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask
                                                     backing:NSBackingStoreBuffered defer:NO];
        screenView = [[VJXOpenGLView alloc] initWithFrame:[screenWindow frame]];
        [[screenWindow contentView] addSubview:screenView];
        [screenWindow setIsVisible:YES];
    }
    return self;
    
}
- (void)outputFrame:(CIImage *)frame
{
    [super outputFrame:frame];
    @synchronized(self) {
        screenView.currentFrame = currentFrame;
        // XXX - setting needsDisplay makes rendering happen in the main gui thread
        // this could lead to undesired behaviours like rendering stopping while 
        // a gui animation is in progress. Calling drawRect directly here, instead, 
        // makes rendering happen in the current thread... which is what we really want
        //[screenView setNeedsDisplay:YES];
        [screenView drawRect:NSZeroRect];
    }
}
@end
