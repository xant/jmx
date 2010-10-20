//
//  VJXVideoFilter.m
//  VeeJay
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXVideoFilter.h"
#import <QuartzCore/CIFilter.h>
#import "VJXContext.h"
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

- (void)selectFilter:(NSString *)filterName
{
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    [newFilter setDefaults];
    NSLog(@"Filter Attributes : %@", [newFilter attributes]);
    NSArray *inputKeys = [newFilter inputKeys];
    NSArray *outputKeys = [newFilter outputKeys];
    NSLog(@"Filter Input params : %@\nFilter Output params%@", inputKeys, outputKeys);
    @synchronized(self) {
        [self unregisterAllPins];
        for (NSString *key in inputKeys) {
            // TODO - use 'attributes' to determine datatype,
            //        max/min values and display name
            if ([key isEqualTo:@"inputImage"]) {
                [self registerInputPin:key withType:kVJXImagePin];
            } else {
                [self registerInputPin:key withType:kVJXNumberPin];
            }
        }
    }
}

@end
