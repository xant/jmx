//
//  JMXRect.mm
//  JMX
//
//  Created by xant on 1/17/11.
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
#import "JMXRect.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXRect

@synthesize nsRect;

+ (id)rectWithNSRect:(NSRect)rect
{
    id obj = [JMXRect alloc];
    return [[obj initWithNSRect:rect] autorelease];
}

- (id)initWithNSRect:(NSRect)rect
{
    self = [super init];
    if (self) {
        self.nsRect = rect;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
        return [self initWithNSRect:NSZeroRect];
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (NSPoint)origin
{
    return nsRect.origin;
}

- (NSSize)size
{
    return nsRect.size;
}

- (void)setX:(CGFloat)x
{
    nsRect.origin.x = x;
}

- (void)setY:(CGFloat)y
{
    nsRect.origin.y = y;
}

- (void)setWidth:(CGFloat)w
{
    nsRect.size.width = w;
}

- (void)setHeight:(CGFloat)h
{
    nsRect.size.height = h;
}

- (CGFloat)x
{
    return nsRect.origin.x;
}

- (CGFloat)y
{
    return nsRect.origin.y;
}

- (BOOL)isEqual:(JMXRect *)object
{
    if (memcmp(&nsRect, object, sizeof(NSRect)) == 0)
        return YES;
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [[JMXRect alloc] initWithNSRect:nsRect];
}

#pragma mark V8

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Rect"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("x"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("y"), GetDoubleProperty, SetDoubleProperty);
    return objectTemplate;
}

static void JMXRectJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXRect *obj = static_cast<JMXRect *>(parameter);
    //NSLog(@"V8 WeakCallback (Rect) called %@", obj);
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
    v8::Handle<FunctionTemplate> objectTemplate = [JMXRect jsObjectTemplate];
    v8::Persistent<Object> jsInstance = v8::Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXRectJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
}

@end

v8::Handle<v8::Value> JMXRectJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    //v8::Locker locker;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXRect jsObjectTemplate];
    int64_t x = 0;
    int64_t y = 0;
    int64_t w = 0;
    int64_t h = 0;
    if (args.Length() >= 2) {
        x = args[0]->IntegerValue();
        y = args[1]->IntegerValue();
        w = args[2]->IntegerValue();
        h = args[3]->IntegerValue();
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXRect *Rect = [[JMXRect rectWithNSRect:NSMakeRect(x, y, w, h)] retain];
    jsInstance.MakeWeak(Rect, JMXRectJSDestructor);
    jsInstance->SetPointerInInternalField(0, Rect);
    [pool drain];
    return handleScope.Close(jsInstance);
}
