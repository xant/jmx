//
//  VJLayer.m
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXLayer.h"


@implementation VJXLayer

@synthesize name, saturation, brightness, contrast;

- (id)init
{
    if (self = [super init]) {
        name = @"Untitled";
        saturation = 1.0;
        brightness = 0.0;
        contrast = 1.0;
    }

    return self;
}

- (void)dealloc {
    [super dealloc];
}

- (CIImage *)frameImageForTime:(uint64_t)timeStamp
{
    [NSException raise:@"Abstract method" format:@"Subclass must implement '%s'", _cmd];
    return nil;
}

@end
