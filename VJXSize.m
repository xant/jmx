//
//  VJXSize.m
//  VeeJay
//
//  Created by xant on 9/5/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXSize.h"


@implementation VJXSize

@synthesize nsSize;

+ (id)sizeWithNSSize:(NSSize)size
{
    id obj = [VJXSize alloc];
    return [[obj initWithNSSize:size] autorelease];
}

- (id)initWithNSSize:(NSSize)size
{
    if (self == [super init]) {
        self.nsSize = size;
    }
    return self;
}

- (id)init
{
    if (self = [super init])
        return [self initWithNSSize:NSZeroSize];
    return self;
}

- (CGFloat)width
{
    return nsSize.width;
}

- (CGFloat)height
{
    return nsSize.height;
}

@end
