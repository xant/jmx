//
//  JMXVideoFilter.mm
//  JMX
//
//  Created by xant on 12/18/10.
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

#define __JMXV8__
#import "JMXVideoFilter.h"
#import "JMXScript.h"

@implementation JMXVideoFilter

@synthesize filter;

+ (NSArray *)availableFilters
{
    return [NSArray arrayWithObject:@""];
}

- (id)init
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.filter = nil;
        self.name = @"VideoFilter";
        inFrame = [self registerInputPin:@"frame" withType:kJMXImagePin andSelector:@"newFrame:"];
        outFrame = [self registerOutputPin:@"frame" withType:kJMXImagePin];

        filterSelector = [self registerInputPin:@"filter"
                                       withType:kJMXStringPin
                                    andSelector:@"setFilter:"];
        [filterSelector addAllowedValues:[[self class] availableFilters]];
    }
    return self;
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    if (filter)
        [filter release];
    [super dealloc];
}

- (NSArray *)availableFilters
{
    return [[self class] availableFilters];
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
// the following global is usually defined by the JMXV8_EXPORT_ENTITY_CLASS() macro
// but we don't want to use it because we don't want to implement a constructor in the native language
static Persistent<FunctionTemplate> objectTemplate;

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
    NSArray *availableFilters;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXVideoFilter *filter = (JMXVideoFilter *)args.Holder()->GetPointerFromInternalField(0);
    if (filter) { // called as instance method
        availableFilters = [filter availableFilters];
    } else { // called as class method
        Class objcClass = (Class)External::Unwrap(args.Holder()->Get(String::NewSymbol("_objcClass")));
        availableFilters = [objcClass availableFilters];
    }
    v8::Handle<Array> list = v8::Array::New([availableFilters count]);
    for (int i = 0; i < [availableFilters count]; i++) {
        list->Set(Number::New(i), String::New([[availableFilters objectAtIndex:i] UTF8String]));
    }
    [pool release];
    handleScope.Close(list);
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> SelectFilter(const Arguments& args)
{
    HandleScope handleScope;
    BOOL ret = NO;
    JMXVideoFilter *filterInstance = (JMXVideoFilter *)args.Holder()->GetPointerFromInternalField(0);
    if (filterInstance) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        NSString *filterName = [NSString stringWithUTF8String:*value];
        filterInstance.filter = filterName;
        if ([filterInstance.filter isEqualTo:filterName])
            ret = YES;
        [pool release];
    }
    return handleScope.Close(v8::Boolean::New(ret));
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //Locker lock;
    HandleScope handleScope;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<v8::FunctionTemplate>::New(v8::FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("VideoFilter"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("availableFilters", FunctionTemplate::New(AvailableFilters));
    classProto->Set("selectFilter", FunctionTemplate::New(SelectFilter));
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("filter"), GetStringProperty, SetStringProperty);
    return objectTemplate;
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    [super jsRegisterClassMethods:constructor]; // let our super register its methods (if any)
    constructor->Set("availableFilters", FunctionTemplate::New(AvailableFilters));
}

@end
