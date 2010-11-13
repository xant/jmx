//
//  JMXPoint.m
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
#import "JMXPoint.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXPoint

@synthesize nsPoint;

+ (id)pointWithNSPoint:(NSPoint)point
{
    id obj = [JMXPoint alloc];
    return [[obj initWithNSPoint:point] autorelease];
}

- (id)initWithNSPoint:(NSPoint)point
{
    self = [super init];
    if (self) {
        self.nsPoint = point;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self)
        return [self initWithNSPoint:NSZeroPoint];
    return self;
}

- (void)setX:(CGFloat)x
{
    nsPoint.x = x;
}

- (void)setY:(CGFloat)y
{
    nsPoint.y = y;
}

- (CGFloat)x
{
    return nsPoint.x;
}

- (CGFloat)y
{
    return nsPoint.y;
}

- (BOOL)isEqual:(JMXPoint *)object
{
    if (nsPoint.y == object.y && nsPoint.x == object.x)
        return YES;
    return NO;
}

+ (v8::Handle<FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Handle<FunctionTemplate> classTemplate = FunctionTemplate::New();
    classTemplate->SetClassName(String::New("Point"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    //classProto->Set("connect", FunctionTemplate::New(connect));
    //classProto->Set("export", FunctionTemplate::New(exportToBoard));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = classTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("x"), GetDoubleProperty, SetDoubleProperty);
    /*
    instanceTemplate->SetAccessor(String::NewSymbol("direction"), direction);
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("multiple"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("continuous"), GetBoolProperty, SetBoolProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("owner"), accessObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("minValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("maxValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("connected"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("sendNotifications"), GetBoolProperty, SetBoolProperty);
     */
    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    return handleScope.Close(classTemplate);
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXPoint jsClassTemplate];
    v8::Handle<Object> jsInstance = classTemplate->InstanceTemplate()->NewInstance();
    v8::Handle<External> external_ptr = External::New(self);
    jsInstance->SetInternalField(0, external_ptr);
    return handle_scope.Close(jsInstance);
}

@end

void JMXPointJSDestructor(Persistent<Value> object, void *parameter)
{
    NSLog(@"V8 WeakCallback called");
    JMXPoint *obj = static_cast<JMXPoint *>(parameter);
    Local<Context> currentContext  = v8::Context::GetCurrent();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        /* this will destroy the javascript object as well */
        [ctx removePersistentInstance:obj];
    } else {
        NSLog(@"Can't find context to attach persistent instance (just leaking)");
    }
}

//static std::map<JMXPoint *, v8::Persistent<v8::Object> > instancesMap;

v8::Handle<v8::Value> JMXPointJSConstructor(const v8::Arguments& args)
{
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> classTemplate = [JMXPoint jsClassTemplate];
    int x = 0;
    int y = 0;
    if (args.Length() >= 2) {
        x = args[0]->IntegerValue();
        y = args[1]->IntegerValue();
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(classTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXPoint *point = [[JMXPoint pointWithNSPoint:NSMakePoint(x, y)] retain];
    jsInstance.MakeWeak(point, &JMXPointJSDestructor);
    //instancesMap[point] = jsInstance;
    v8::Handle<External> external_ptr = External::New(point);
    jsInstance->SetInternalField(0, external_ptr);
    Local<Context> currentContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext:currentContext];
    if (ctx) {
        [ctx addPersistentInstance:jsInstance obj:point];
    } else {
        NSLog(@"Can't find context to attach persistent instance (just leaking)");
    }
    [pool release];
    return handle_scope.Close(jsInstance);
}
