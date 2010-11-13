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
}

- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
}

- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawTriangle:points strokeColor:strokeColor fillColor:fillColor];
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [drawPath drawCircle:center radius:radius strokeColor:strokeColor fillColor:fillColor];
}

- (void)tick:(uint64_t)timeStamp
{
    [outputFramePin deliverData:drawPath.currentFrame];
    [super tick:timeStamp];
}

#pragma mark V8
using namespace v8;

static v8::Handle<Value> drawCircle(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXDrawEntity *entity = (JMXDrawEntity *)wrap->Value();
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    v8::Handle<Object> origin = args[0]->ToObject();
    JMXPoint *point = (JMXPoint *)origin->GetPointerFromInternalField(0);
    [entity drawCircle:point radius:20 strokeColor:[NSColor whiteColor] fillColor:[NSColor whiteColor]];
    return v8::Undefined();
}

+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    v8::Handle<v8::FunctionTemplate> entityTemplate = [super jsClassTemplate];
    entityTemplate->SetClassName(String::New("DrawPath"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("drawCircle", FunctionTemplate::New(drawCircle));
    //classProto->Set("close", FunctionTemplate::New(close));
    return handleScope.Close(entityTemplate);
}

@end
