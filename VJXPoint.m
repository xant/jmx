//
//  VJXPoint.m
//  VeeJay
//
//  Created by xant on 9/5/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXPoint.h"


@implementation VJXPoint

@synthesize nsPoint;

+ (id)pointWithNSPoint:(NSPoint)point
{
    id obj = [VJXPoint alloc];
    return [[obj initWithNSPoint:point] autorelease];
}

- (id)initWithNSPoint:(NSPoint)point
{
    if (self == [super init]) {
        self.nsPoint = point;
    }
    return self;
}

- (id)init
{
    if (self = [super init])
        return [self initWithNSPoint:NSZeroPoint];
    return self;
}

- (CGFloat)x
{
    return nsPoint.x;
}

- (CGFloat)y
{
    return nsPoint.y;
}

@end
