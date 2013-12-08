//
//  JMXCoreImageFilter.m
//  JMX
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <QuartzCore/CIFilter.h>
#import "JMXContext.h"
#define __JMXV8__
#import "NSColor+V8.h"
#import "JMXCoreImageFilter.h"
#import "JMXV8PropertyAccessors.h"
#import "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXCoreImageFilter);

@interface JMXCoreImageFilter ()
{
    OSSpinLock flock;
}
@end

@implementation JMXCoreImageFilter

+ (NSArray *)availableFilters
{
    NSMutableArray *knownFilters = [[super availableFilters] mutableCopy];
    NSArray *categories = [NSArray arrayWithObjects:kCICategoryDistortionEffect,
                           kCICategoryGeometryAdjustment,
                           kCICategoryColorEffect,
                           kCICategoryColorEffect,
                           kCICategoryStylize,
                           kCICategorySharpen,
                           kCICategoryBlur,
                           kCICategoryHalftoneEffect,
                           nil];
    for (NSString *category in categories) {
        NSArray *filtersInCategory = [CIFilter filterNamesInCategory:category];
        [knownFilters addObjectsFromArray:filtersInCategory];
    }
    return [knownFilters autorelease];
}

- (id)init
{
    self = [super init];
    if (self) {
        ciFilter = nil;
        self.label = @"CoreImageFilter";
    }
    return self;
}

- (void)dealloc
{
    if (ciFilter)
        [ciFilter release];
    [super dealloc];
}

- (void)newFrame:(CIImage *)frame
{
    OSSpinLockLock(&flock);
    if (currentFrame)
        [currentFrame release];
    if (ciFilter) {
        [ciFilter setValue:frame forKey:@"inputImage"];
        currentFrame = [[ciFilter valueForKey:@"outputImage"] retain];
    } else {
        currentFrame = [frame retain];
    }
    [outFrame deliverData:currentFrame];
    OSSpinLockUnlock(&flock);
}

- (void)setFilterValue:(id)value userData:(id)userData
{
    NSString *pinName = (NSString *)userData;
    OSSpinLockLock(&flock);
    if (ciFilter) {
        @try {
            if ([value isKindOfClass:[JMXPoint class]]) { // XXX
                [ciFilter setValue:[CIVector vectorWithX:[value x] Y:[value y]] forKey:pinName];
            } else if ([value isKindOfClass:[NSColor class]]) {
                CIColor *color = [CIColor colorWithRed:[value redComponent]
                                                 green:[value greenComponent]
                                                  blue:[value blueComponent]];
                [ciFilter setValue:color forKey:pinName];
            } else {
                [ciFilter setValue:value forKey:pinName];
            }
        }
        @catch (NSException * e) {
            // key doesn't exist
        }
    }
    OSSpinLockUnlock(&flock);
}

- (void)removeFilterAttributesPins
{
    for (JMXInputPin *pin in [self inputPins]) {
        // TODO - extendable [JMXEntity defaultInputPins]
        if (![pin.label isEqualToString:@"frame"] &&
            ![pin.label isEqualToString:@"filter"] &&
            ![pin.label isEqualToString:@"active"])
        {
            [self unregisterInputPin:pin.label];
        }
    }
    for (JMXOutputPin *pin in [self outputPins]) {
        // TODO - extendable [JMXEntity defaultOutputPins]
        if (![pin.label isEqualToString:@"frame"] &&
            ![pin.label isEqualToString:@"active"])
        {
            [self unregisterOutputPin:pin.label];
        }
    }
}

- (void)setFilter:(NSString *)filterName
{
    if ([filterName length] == 0) {
        if (filter)
            [filter release];
        filter = nil;
        [self removeFilterAttributesPins];
        [self notifyModifications];
    }
        
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter) {
        [newFilter setDefaults];
        //NSLog(@"Filter Attributes : %@", [newFilter attributes]);
        NSArray *inputKeys = [newFilter inputKeys];
        NSDictionary *attributes = [newFilter attributes];
        OSSpinLockLock(&flock);
            [self removeFilterAttributesPins];
            for (NSString *key in inputKeys) {
                // TODO - max/min values and display name
                if (![key isEqualTo:@"inputImage"]) {
                    NSDictionary *inputParam = [attributes objectForKey:key];
                    NSString *type = [inputParam objectForKey:@"CIAttributeClass"];
                    JMXInputPin *inputPin = nil;
                    if ([type isEqualTo:@"NSNumber"]) {
                        inputPin = [self registerInputPin:key withType:kJMXNumberPin andSelector:@"setFilterValue:userData:" userData:key];
                    } else if ([type isEqualTo:@"CIVector"]) {
                        inputPin = [self registerInputPin:key withType:kJMXPointPin andSelector:@"setFilterValue:userData:" userData:key];
                    } else if ([type isEqualTo:@"CIColor"]) {
                        inputPin = [self registerInputPin:key withType:kJMXColorPin andSelector:@"setFilterValue:userData:" userData:key];
                    } else if ([type isEqualTo:@"CIImage"]) {
                        inputPin = [self registerInputPin:key withType:kJMXImagePin andSelector:@"setFilterValue:userData:" userData:key];
                    } else {
                        NSLog(@"Unhandled datatype %@", type);
                    }
                    if (inputPin) {
                        [inputPin setMinLimit:[inputParam objectForKey:@"CIAttributeSliderMin"]];
                        [inputPin setMaxLimit:[inputParam objectForKey:@"CIAttributeSliderMax"]];
                    }
                }
            }
            if (ciFilter)
                [ciFilter release];
            ciFilter = [newFilter retain];
        OSSpinLockUnlock(&flock);
        if (filter)
            [filter release];
        filter = [filterName copy];
        [self notifyModifications];
    }
}

#pragma mark V8
using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //Locker lock;
    HandleScope handleScope;
    objectTemplate = v8::Persistent<v8::FunctionTemplate>::New(v8::FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("CoreImageFilter"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    return objectTemplate;
}
@end
