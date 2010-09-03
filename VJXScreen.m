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
        [self registerInputPin:@"inputFrame" withType:kVJXImagePin andSelector:@"outputFrame:"];
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

- (void)outputFrame:(CIImage *)frame
{
    @synchronized(self) {
        currentFrame = [frame retain];
    }
}

@end
