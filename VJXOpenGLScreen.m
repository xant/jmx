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

@end
