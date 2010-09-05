//
//  VJXScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXScreen.h"


@implementation VJXScreen

- (id)initWithSize:(NSSize)screenSize
{
    if (self = [super init]) {
        currentFrame = nil;
        memcpy(&size, &screenSize, sizeof(size));
        [self registerInputPin:@"inputFrame" withType:kVJXImagePin andSelector:@"drawFrame:"];
        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kVJXNumberPin];
    }
    return self;
}

- (id)init
{
    NSSize defaultSize = { 640, 480 };
    return [self initWithSize:defaultSize];
}

- (void)drawFrame:(CIImage *)frame
{
    @synchronized(self) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [frame retain];
    }
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    [super dealloc];
}

@end
