//
//  JMXSize.m
//  JMX
//
//  Created by xant on 9/5/10.
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

#define __JMXV8__ 1
#import "JMXSize.h"
#import "JMXScript.h"
@implementation JMXSize

@synthesize nsSize;

+ (id)sizeWithNSSize:(NSSize)size
{
    id obj = [JMXSize alloc];
    return [[obj initWithNSSize:size] autorelease];
}

- (id)initWithNSSize:(NSSize)size
{
    self = [super init];
    if (self) {
        self.nsSize = size;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
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

- (void)setWidth:(CGFloat)width
{
    nsSize.width = width;
}

- (void)setHeight:(CGFloat)height
{
    nsSize.height = height;
}

- (BOOL)isEqual:(JMXSize *)object
{
    if ([object isKindOfClass:[JMXSize class]] && 
        nsSize.height == object.height &&
        nsSize.width == object.width)
    {
        return YES;
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [[JMXSize alloc] initWithNSSize:nsSize];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"JMXSize: { w: %f, h: %f }", self.width, self.height];
}

#pragma mark V8
using namespace v8;
static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    //v8::Handle<FunctionTemplate> objectTemplate = FunctionTemplate::New();
    objectTemplate->SetClassName(String::New("Size"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetDoubleProperty, SetDoubleProperty);

    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    return objectTemplate;
}

static void JMXSizeJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXSize *obj = static_cast<JMXSize *>(parameter);
    //NSLog(@"V8 WeakCallback (Size) called %@", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXSize jsObjectTemplate];
    v8::Persistent<Object> jsInstance = v8::Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXSizeJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
}

@end

v8::Handle<v8::Value> JMXSizeJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    //v8::Locker locker;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXSize jsObjectTemplate];
    int width = 0;
    int height = 0;
    if (args.Length() >= 2) {
        width = args[0]->IntegerValue();
        height = args[1]->IntegerValue();
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXSize *size = [[JMXSize sizeWithNSSize:NSMakeSize(width, height)] retain];
    jsInstance.MakeWeak(size, JMXSizeJSDestructor);
    jsInstance->SetPointerInInternalField(0, size);
    [pool drain];
    return handleScope.Close(jsInstance);
}
