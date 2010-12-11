//
//  JMXCoreImageFilter.m
//  JMX
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <QuartzCore/CIFilter.h>
#import "JMXContext.h"
#define __JMXV8__
#import "JMXCoreImageFilter.h"
#import "JMXScript.h"
#import "JMXColor.h"

JMXV8_EXPORT_ENTITY_CLASS(JMXCoreImageFilter);

@implementation JMXCoreImageFilter

@synthesize knownFilters, filter;

- (id)init
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.filter = nil;
        ciFilter = nil;
        inFrame = [self registerInputPin:@"frame" withType:kJMXImagePin andSelector:@"newFrame:"];
        outFrame = [self registerOutputPin:@"frame" withType:kJMXImagePin];
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
                                       withType:kJMXStringPin
                                    andSelector:@"setFilter:"
                                  allowedValues:knownFilters
                                   initialValue:[knownFilters objectAtIndex:0]];
    }
    return self;
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    if (ciFilter)
        [ciFilter release];
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
        if (ciFilter) {
            [ciFilter setValue:frame forKey:@"inputImage"];
            currentFrame = [[ciFilter valueForKey:@"outputImage"] retain];
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
        if (ciFilter) {
            @try {
                if ([value isKindOfClass:[JMXPoint class]]) { // XXX
                    [ciFilter setValue:[CIVector vectorWithX:[value x] Y:[value y]] forKey:pinName];
                } else if ([value isKindOfClass:[JMXColor class]]) {
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
    }
}

- (void)setFilter:(NSString *)filterName
{
    CIFilter *newFilter = [CIFilter filterWithName:filterName];
    if (newFilter) {
        [newFilter setDefaults];
        //NSLog(@"Filter Attributes : %@", [newFilter attributes]);
        NSArray *inputKeys = [newFilter inputKeys];
        NSDictionary *attributes = [newFilter attributes];
        @synchronized(self) {
            for (NSString *pinName in [[inputPins copy] autorelease]) {
                // TODO - extendable [JMXEntity defaultInputPins]
                if (pinName != @"frame" && pinName != @"filter" && pinName != @"active")
                    [self unregisterInputPin:pinName];
            }
            for (NSString *pinName in [[outputPins copy] autorelease]) {
                // TODO - extendable [JMXEntity defaultOutputPins]
                if (pinName != @"frame" && pinName != @"active")
                    [self unregisterOutputPin:pinName];
            }
            for (NSString *key in inputKeys) {
                // TODO - max/min values and display name
                if (![key isEqualTo:@"inputImage"]) {
                    NSDictionary *inputParam = [attributes objectForKey:key];
                    NSString *type = [inputParam objectForKey:@"CIAttributeClass"];
                    JMXInputPin *inputPin;
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
        }
        if (filter)
            [filter release];
        filter = [filterName copy];
        [self notifyModifications];
    }
}

#pragma mark V8

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    v8::Handle<Value> arg = (*args)[0];
    v8::String::Utf8Value value(arg);
    self.filter = [NSString stringWithUTF8String:*value];
}

static v8::Handle<Value> AvailableFilters(const Arguments& args)
{
    HandleScope handleScope;
    JMXCoreImageFilter *filter = (JMXCoreImageFilter *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Handle<Array> list = v8::Array::New([filter.knownFilters count]);
    for (int i = 0; i < [filter.knownFilters count]; i++) {
        list->Set(Number::New(i), String::New([[filter.knownFilters objectAtIndex:i] UTF8String]));
    }
    [pool release];
    return handleScope.Close(list);
}

static v8::Handle<Value> SelectFilter(const Arguments& args)
{
    HandleScope handleScope;
    BOOL ret = NO;
    JMXCoreImageFilter *filterInstance = (JMXCoreImageFilter *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSString *filterName = [NSString stringWithUTF8String:*value];
    {
        v8::Unlocker unlocker;
        filterInstance.filter = filterName;
        if ([filterInstance.filter isEqualTo:filterName])
            ret = YES;
    }
    [pool release];
    return handleScope.Close(v8::Boolean::New(ret));
}

#pragma mark V8

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    //Locker lock;
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = v8::Persistent<v8::FunctionTemplate>::New(v8::FunctionTemplate::New());
    entityTemplate->Inherit([super jsClassTemplate]);
    entityTemplate->SetClassName(String::New("CoreImageFilter"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("avaliableFilters", FunctionTemplate::New(AvailableFilters));
    classProto->Set("selectFilter", FunctionTemplate::New(SelectFilter));
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("filter"), GetStringProperty, SetStringProperty);
    return entityTemplate;
}

@end
