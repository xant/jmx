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
#import "JMXThreadedEntity.h"

JMXV8_EXPORT_NODE_CLASS(JMXDrawEntity);

@implementation JMXDrawEntity

- (id)init
{
    self = [super init];
    if (self) {
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:self.size];
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        self.label = @"DrawPath";
        if (threadedEntity)
            return threadedEntity;
    }
    return nil;
}

- (void)dealloc
{
    [drawPath release];
    [super dealloc];
}

- (void)drawRect:(JMXPoint *)rectOrigin size:(JMXSize *)rectSize strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    @synchronized(drawPath) {
        [drawPath drawRect:rectOrigin size:rectSize strokeColor:strokeColor fillColor:fillColor];
    }
}

- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    @synchronized(drawPath) {
        [drawPath drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
    }
}

- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    @synchronized(drawPath) {
        [drawPath drawTriangle:points strokeColor:strokeColor fillColor:fillColor];
    }
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    @synchronized(drawPath) {
        [drawPath drawCircle:center radius:radius strokeColor:strokeColor fillColor:fillColor];
    }
}

- (void)clear
{
    // XXX - should lock here ?
    [drawPath clear];
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(drawPath) {
        [drawPath render];
        if (currentFrame)
            [currentFrame release];
        currentFrame = [drawPath.currentFrame retain];
    }
    [super tick:timeStamp];
}

#pragma mark V8
using namespace v8;

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length() >= 2 && (*args)[0]->IsNumber() && (*args)[1]->IsNumber()) {
        NSSize newSize;
        newSize.width = (*args)[0]->ToNumber()->NumberValue();
        newSize.height = (*args)[1]->ToNumber()->NumberValue();
        [self setSize:[JMXSize sizeWithNSSize:newSize]];
    } else if (args->Length() >= 1 && (*args)[0]->IsObject()) {
        v8::Handle<Object>sizeObj = (*args)[0]->ToObject();
        if (!sizeObj.IsEmpty()) {
            JMXSize *jmxSize = (JMXSize *)sizeObj->GetPointerFromInternalField(0);
            if (jmxSize)
                [self setSize:jmxSize];
        }
    }
}

static v8::Handle<Value> drawPolygon(const Arguments& args)
{
    HandleScope handleScope;
    //Locker locker;
    JMXDrawEntity *entity = (JMXDrawEntity *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() >= 1 && args[0]->IsArray()) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Array> pointList = v8::Handle<Array>::Cast(args[0]);
        NSMutableArray *points = [[NSMutableArray alloc] init];
        for (int i = 0; i < pointList->Length(); i++) {
            v8::Local<Object>pointObj = v8::Local<Object>::Cast(pointList->Get(i));
            [points addObject:(JMXPoint *)pointObj->GetPointerFromInternalField(0)];
        }
        NSColor *strokeColor = [[NSColor whiteColor] retain];
        NSColor *fillColor = nil;
        if (args.Length() >= 2 && args[1]->IsObject()) {
            v8::Local<Object>colorObj = args[1]->ToObject();
            if (!colorObj.IsEmpty())
                strokeColor = [(JMXColor *)colorObj->GetPointerFromInternalField(0) retain]; 
        }
        if (args.Length() >= 3 && args[2]->IsObject()) {
            v8::Local<Object>colorObj = args[2]->ToObject();
            if (!colorObj.IsEmpty())
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
    Locker locker;
    JMXDrawEntity *entity = (JMXDrawEntity *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() >= 1 && args[0]->IsObject()) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        double radius = 0;
        v8::Handle<Object> origin = args[0]->ToObject();
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
                v8::Handle<Object>colorObj = args[2]->ToObject();
                strokeColor = (JMXColor *)colorObj->GetPointerFromInternalField(0);
                if (strokeColor)
                    [strokeColor retain];
            }
            if (args.Length() >= 4) {
                v8::Handle<Object>colorObj = args[3]->ToObject();
                fillColor = (JMXColor *)colorObj->GetPointerFromInternalField(0);
                if (fillColor)
                    [fillColor retain];
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
    Locker locker;
    v8::Handle<Object> self = args.Holder();
    JMXDrawEntity *entity = (JMXDrawEntity *)self->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [entity clear];
    [pool release];
    return v8::Undefined();
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    NSLog(@"JMXDrawEntity objectTemplate created");
    v8::Persistent<v8::FunctionTemplate> entityTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    entityTemplate->Inherit([super jsObjectTemplate]);
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
