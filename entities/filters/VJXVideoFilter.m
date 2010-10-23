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
    self = [super init];
    if (self) {
        currentFrame = nil;
        filter = nil;
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
        if (filter) {
            [filter setValue:frame forKey:@"inputImage"];
            currentFrame = [[filter valueForKey:@"outputImage"] retain];
        } else {
            currentFrame = [frame retain];
        }
        [outFrame deliverData:currentFrame];
    }
}

- (void)setFilterValue:(id)value userData:(id)userData
{
    NSString *pinName = (NSString *)userData;
    @synchronized(self) {
        if (filter) {
            [filter setValue:value forKey:pinName];
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
        for (NSString *pinName in [[inputPins copy] autorelease]) {
            // TODO - extendable [VJXEntity defaultInputPins]
            if (pinName != @"frame" && pinName != @"filter" && pinName != @"active")
                [self unregisterInputPin:pinName];
        }
        for (NSString *pinName in [[outputPins copy] autorelease]) {
            // TODO - extendable [VJXEntity defaultOutputPins]
            if (pinName != @"frame" && pinName != @"active")
                [self unregisterOutputPin:pinName];
        }
        for (NSString *key in inputKeys) {
            // TODO - use 'attributes' to determine datatype,
            //        max/min values and display name
            if (![key isEqualTo:@"inputImage"]) {
                [self registerInputPin:key withType:kVJXNumberPin andSelector:@"setFilterValue:userData:" userData:key];
            }
        }
        if (filter)
            [filter release];
        filter = [newFilter retain];
    }
    [self notifyModifications];
}

@end
