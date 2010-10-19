//
//  VJXVideoFilter.m
//  VeeJay
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXVideoFilter.h"
#import <QuartzCore/CIFilter.h>

@implementation VJXVideoFilter

- (id)init
{
    if (self = [super init]) {
        inFrame = [self registerInputPin:@"frame" withType:kVJXImagePin andSelector:@"newFrame:"];
        outFrame = [self registerOutputPin:@"frame" withType:kVJXImagePin];
        NSArray *categories = [NSArray arrayWithObjects:kCICategoryDistortionEffect,
                               kCICategoryGeometryAdjustment,
                               kCICategoryColorEffect,
                               kCICategoryColorEffect,
                               kCICategoryStylize,
                               kCICategorySharpen,
                               kCICategoryBlur,
                               kCICategoryHalftoneEffect,
                               nil];
        knownFilters = [[NSMutableArray alloc] init];
        for (NSString *category in categories) {
            NSArray *filtersInCategory = [CIFilter filterNamesInCategory:category];
            [knownFilters addObjectsFromArray:filtersInCategory];
        }
        filterSelector = [self registerInputPin:@"filter"
                                       withType:kVJXStringPin
                                    andSelector:@"selectFilter:"
                                   allowedValues:knownFilters
                                   initialValue:[knownFilters objectAtIndex:0]];
        currentFrame = nil;
        filter = nil;
    }
    return self;
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    if (filter)
        [filter release];
    if (knownFilters)
        [knownFilters release];
    [super dealloc];
}

- (void)newFrame:(CIImage *)frame
{
    @synchronized(self) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [frame retain];
        if (filter) {
            
        }
    }
}

- (void)selectFilter:(NSString *)filter
{
}

@end
