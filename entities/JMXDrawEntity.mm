//
//  JMXDrawEntity.m
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXDrawEntity.h"
#include "JMXScript.h"
#import "JMXColor.h"

JMXV8_EXPORT_ENTITY_CLASS(JMXDrawEntity);

@implementation JMXDrawEntity

- (id)init
{
    self = [super init];
    if (self) {
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:self.size];
    }
    return self;
}

- (void)dealloc
{
    [drawPath release];
    [super dealloc];
}

- (void)drawRect:(JMXPoint *)rectOrigin size:(JMXSize *)rectSize strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawRect:rectOrigin size:rectSize strokeColor:strokeColor fillColor:fillColor];
    [drawPath render];
}

- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
    [drawPath render];
}

- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawTriangle:points strokeColor:strokeColor fillColor:fillColor];
    [drawPath render];
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawCircle:center radius:radius strokeColor:strokeColor fillColor:fillColor];
    [drawPath render];
}

- (void)clear
{
    [drawPath clear];
}

- (void)tick:(uint64_t)timeStamp
{
    [outputFramePin deliverData:drawPath.currentFrame];
    [super tick:timeStamp];
}

#pragma mark V8
using namespace v8;

static v8::Handle<Value> drawPolygon(const Arguments& args)
{
    HandleScope handleScope;
    v8::Handle<Object> self = args.Holder();
    v8::Handle<External> wrap = v8::Handle<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    if (args.Length() >= 1 && args[0]->IsArray()) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Value> arg = args[0];
        v8::Handle<Array> pointList = v8::Handle<Array>::Cast(args[0]);
        NSMutableArray *points = [[NSMutableArray alloc] init];
        for (int i = 0; i < pointList->Length(); i++) {
            v8::Handle<Object>pointObj = v8::Handle<Object>::Cast(pointList->Get(i));
            JMXPoint *point = [(JMXPoint *)pointObj->GetPointerFromInternalField(0) retain];
            [points addObject:[point autorelease]];
        }
        NSColor *strokeColor = [[NSColor whiteColor] retain];
        NSColor *fillColor = nil;
        if (args.Length() >= 2) {
            v8::Handle<Object>colorObj = args[1]->ToObject();
            strokeColor = [(JMXColor *)colorObj->GetPointerFromInternalField(0) retain]; 
        }
        if (args.Length() >= 3) {
            v8::Handle<Object>colorObj = args[2]->ToObject();
            fillColor = [(JMXColor *)colorObj->GetPointerFromInternalField(0) retain]; 
        }
        [entity drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
        [points release];
        [strokeColor release];
        if (fillColor)
            [fillColor release];
        [pool drain];
    }
    return v8::Undefined();
}

static v8::Handle<Value> drawCircle(const Arguments& args)
{
    HandleScope handleScope;
    v8::Locker lock;
    v8::Handle<Object> self = args.Holder();
    v8::Handle<External> wrap = v8::Handle<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    if (args.Length() >= 1 && args[0]->IsObject()) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        double radius = 0;
        v8::Local<Object> origin = args[0]->ToObject();
        if (!origin.IsEmpty()) {
            JMXPoint *point = [(JMXPoint *)origin->GetPointerFromInternalField(0) retain];
            if (args.Length() >= 2) {
                if (args[1]->IsNumber()) {
                    radius = args[1]->ToNumber()->NumberValue();
                } else {
                    // TODO - Error Messages
                }
            }
            NSColor *strokeColor = [[NSColor whiteColor] retain];
            NSColor *fillColor = nil;
            if (args.Length() >= 3) {
                v8::Local<Object>colorObj = args[2]->ToObject();
                strokeColor = [(JMXColor *)colorObj->GetPointerFromInternalField(0) retain];
            }
            if (args.Length() >= 4) {
                v8::Local<Object>colorObj = args[3]->ToObject();
                fillColor = [(JMXColor *)colorObj->GetPointerFromInternalField(0) retain]; 
            }
            [entity drawCircle:point radius:radius strokeColor:strokeColor fillColor:fillColor];
            [point release];
            [strokeColor release];
            if (fillColor)
                [fillColor release];
        }
        [pool drain];
    }
    return v8::Undefined();
}

static v8::Handle<Value> clear(const Arguments& args)
{
    HandleScope handleScope;
    v8::Handle<Object> self = args.Holder();
    v8::Handle<External> wrap = v8::Handle<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity clear];
    [pool release];
    return v8::Undefined();
}

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    NSLog(@"JMXDrawEntity ClassTemplate created");
    v8::Persistent<v8::FunctionTemplate> entityTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    entityTemplate->Inherit([super jsClassTemplate]);
    entityTemplate->SetClassName(String::New("DrawPath"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    classProto->Set("drawCircle", FunctionTemplate::New(drawCircle));
    classProto->Set("drawPolygon", FunctionTemplate::New(drawPolygon));
    classProto->Set("drawTriangle", FunctionTemplate::New(drawPolygon));
    classProto->Set("clear", FunctionTemplate::New(clear));
    //classProto->Set("close", FunctionTemplate::New(close));
    return entityTemplate;
}

@end
