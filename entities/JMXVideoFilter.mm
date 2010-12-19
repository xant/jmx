//
//  JMXVideoFilter.mm
//  JMX
//
//  Created by xant on 12/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXVideoFilter.h"
#import "JMXScript.h"

@implementation JMXVideoFilter

@synthesize knownFilters, filter;

- (id)init
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.filter = nil;
        inFrame = [self registerInputPin:@"frame" withType:kJMXImagePin andSelector:@"newFrame:"];
        outFrame = [self registerOutputPin:@"frame" withType:kJMXImagePin];

        knownFilters = [[NSMutableArray alloc] init];
        filterSelector = [self registerInputPin:@"filter"
                                       withType:kJMXStringPin
                                    andSelector:@"setFilter:"];
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

- (void)setFilterValue:(id)value userData:(id)userData
{
    // Do nothing in the base implementation
}

- (void)setFilter:(NSString *)filterName
{
    // Do nothing in the base implementation
}
#pragma mark V8

using namespace v8;
+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    //Locker lock;
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = v8::Persistent<v8::FunctionTemplate>::New(v8::FunctionTemplate::New());
    entityTemplate->Inherit([super jsClassTemplate]);
    entityTemplate->SetClassName(String::New("CoreImageFilter"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    return entityTemplate;
}

@end
