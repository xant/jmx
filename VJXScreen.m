//
//  VJXScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXScreen.h"


@implementation VJXScreen
- (id)init
{
    if (self = [super init]) {
        currentFrame = nil;
        [self registerInputPin:@"inputFrame" withType:kVJXImagePin];
        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kVJXNumberPin];
    }
    return self;
}
@end
