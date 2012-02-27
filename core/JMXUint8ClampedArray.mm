//
//  JMXUint8ClampedArray.m
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//


#define __JMXV8__ 1
#import "JMXUint8ClampedArray.h"
#import "JMXScript.h"
#import <Quartz/Quartz.h>

using namespace v8;
@implementation JMXUint8ClampedArray

+ (id)uint8ClampedArrayWithBytes:(uint8_t *)bytes length:(size_t)length
{
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

+ (id)uint8ClampedArrayWithBytesNoCopy:(uint8_t *)bytes
                          length:(size_t)length
                   freeOnRelease:(BOOL)freeOnRelease
{
    return [[[self alloc] initWithBytesNoCopy:bytes
                                 length:length
                          freeOnRelease:freeOnRelease] autorelease];
}

- (void)dealloc
{
    [super dealloc];
}

#pragma mark -
#pragma mark V8

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Uint8ClampedArray"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("x"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("y"), GetDoubleProperty, SetDoubleProperty);
    return objectTemplate;
}

@end

