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
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    if (args.Length() >= 1 && args[0]->IsArray()) {
        v8::Handle<Value> arg = args[0];
        v8::Handle<Array> pointList = v8::Handle<Array>::Cast(args[0]);
        NSMutableArray *points = [[NSMutableArray alloc] init];
        for (int i = 0; i < pointList->Length(); i++) {
            v8::Handle<Object>pointObj = v8::Handle<Object>::Cast(pointList->Get(i));
            JMXPoint *point = (JMXPoint *)pointObj->GetPointerFromInternalField(0);
            [points addObject:point];
        }
        NSColor *strokeColor = [NSColor whiteColor];
        NSColor *fillColor = nil;
        if (args.Length() >= 2) {
            v8::Handle<Object>colorObj = args[1]->ToObject();
            strokeColor = (JMXColor *)colorObj->GetPointerFromInternalField(0); 
        }
        if (args.Length() >= 3) {
            v8::Handle<Object>colorObj = args[2]->ToObject();
            fillColor = (JMXColor *)colorObj->GetPointerFromInternalField(0); 
        }
        [entity drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
    }
    return v8::Undefined();
}

static v8::Handle<Value> drawCircle(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    if (args.Length() >= 1 && args[0]->IsObject()) {
        double radius = 0;
        v8::Handle<Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        v8::Handle<Object> origin = args[0]->ToObject();
        JMXPoint *point = (JMXPoint *)origin->GetPointerFromInternalField(0);
        if (args.Length() >= 2) {
            if (args[1]->IsNumber()) {
                radius = args[1]->ToNumber()->NumberValue();
            } else {
                // TODO - Error Messages
            }
        }
        NSColor *strokeColor = [NSColor whiteColor];
        NSColor *fillColor = nil;
        if (args.Length() >= 3) {
            v8::Handle<Object>colorObj = args[2]->ToObject();
            strokeColor = (JMXColor *)colorObj->GetPointerFromInternalField(0);
        }
        if (args.Length() >= 4) {
            v8::Handle<Object>colorObj = args[3]->ToObject();
            fillColor = (JMXColor *)colorObj->GetPointerFromInternalField(0); 
        }
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        [entity drawCircle:point radius:radius strokeColor:strokeColor fillColor:fillColor];
        [pool release];
    }
    return v8::Undefined();
}

static v8::Handle<Value> clear(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity clear];
    [pool release];
    return v8::Undefined();
}

+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    v8::Handle<v8::FunctionTemplate> entityTemplate = [super jsClassTemplate];
    entityTemplate->SetClassName(String::New("DrawPath"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("drawCircle", FunctionTemplate::New(drawCircle));
    classProto->Set("clear", FunctionTemplate::New(clear));
    //classProto->Set("close", FunctionTemplate::New(close));
    return handleScope.Close(entityTemplate);
}

@end
