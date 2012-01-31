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

@synthesize buffer;

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


- (id)initWithBytes:(uint8_t *)bytes length:(size_t)length
{
    self = [super init];
    if (self) {
        buffer = (uint8_t *)calloc(length, sizeof(uint8_t));
        if (!buffer) {
            // TODO - log an error
            return nil;
        }
        mustFreeOnRelease = YES;
    }
    return self;
}

- (id)initWithBytesNoCopy:(uint8_t *)bytes
             length:(size_t)length
      freeOnRelease:(BOOL)freeOnRelease;
{
    self = [super init];
    if (self) {
        buffer = bytes;
        if (!buffer) {
            // TODO - log an error
            return nil;
        }
        mustFreeOnRelease = freeOnRelease;
    }
    return self;
}

- (void)dealloc
{
    if (mustFreeOnRelease)
        free(buffer);
    [super dealloc];
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

static void JMXUint8ClampedArrayJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    Locker lock;
    JMXUint8ClampedArray *obj = static_cast<JMXUint8ClampedArray *>(parameter);
    //NSLog(@"V8 WeakCallback (Rect) called %@", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (Handle<Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    Handle<FunctionTemplate> objectTemplate = [JMXUint8ClampedArray jsObjectTemplate];
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    jsInstance.MakeWeak([self retain], JMXUint8ClampedArrayJSDestructor);
    return handle_scope.Close(jsInstance);
}

@end

