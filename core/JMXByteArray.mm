//
//  JMXByteArray.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXByteArray.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXByteArray

@synthesize buffer, size;

+ (id)byteArrayWithBytes:(uint8_t *)bytes length:(size_t)length
{
    return [[[self alloc] initWithBytes:bytes length:length] autorelease];
}

+ (id)byteArrayWithBytesNoCopy:(uint8_t *)bytes
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
            [self release];
            return nil;
        }
        memcpy(buffer, bytes, length);
        size = length;
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
        size = length;
        if (!buffer) {
            // TODO - log an error
            [self release];
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

- (uint8_t)byteAtIndex:(NSInteger)index
{
    if (size > index)
        return buffer[index];
    return 0;
}

#pragma mark -
#pragma mark V8

static v8::Handle<Value> ByteAtIndex(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXByteArray *byteArray = (JMXByteArray *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    if (arg->IsInt32()) {
        //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Value> ret = v8::Number::New([byteArray byteAtIndex:arg->ToInteger()->IntegerValue()]);
        //[pool release];
        return handleScope.Close(ret);
    }
    return handleScope.Close(Undefined());
  
}
static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("ByteArray"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("byteAtIndex", FunctionTemplate::New(ByteAtIndex));

    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetAccessor(String::NewSymbol("size"), GetIntProperty);
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    return objectTemplate;
}

static void JMXByteArrayJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    Locker lock;
    JMXByteArray *obj = static_cast<JMXByteArray *>(parameter);
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
    Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    jsInstance.MakeWeak([self retain], JMXByteArrayJSDestructor);
    return handle_scope.Close(jsInstance);
}

@end
