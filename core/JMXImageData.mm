//
//  JMXImageData.m
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXImageData.h"
#import "JMXScript.h"
#import "JMXUint8ClampedArray.h"

#import <Quartz/Quartz.h>

using namespace v8;

@implementation JMXImageData

@synthesize size;

+ (id)imageDataWithImage:(CIImage *)image rect:(CGRect)rect
{
    return [[[JMXImageData alloc] initWithImage:image rect:rect] autorelease];
}

+ (id)imageDataWithData:(NSData *)data size:(CGSize)s
{
    JMXImageData *obj = [[JMXImageData alloc] initWithData:data];
    obj.size = s;
    return [obj autorelease];
}

+ (id)imageWithSize:(CGSize)size
{
    return [[[JMXImageData alloc] initWithSize:size] autorelease];
}

- (id)initWithImage:(CIImage *)image rect:(CGRect)rect
{
    self = [self initWithSize:rect.size];
    if (self) {
        CIContext *context = [[NSGraphicsContext currentContext] CIContext];
        [context render:image toBitmap:data.buffer rowBytes:size.width*4
                 bounds:CGRectMake(0, 0, size.width, size.height)
                 format:kCIFormatARGB8 colorSpace:NULL];
        
        self.size = rect.size;
    }
    return self;
}

- (id)initWithSize:(CGSize)s
{
    self = [super init];
    if (self) {
        ssize_t bufferLen = s.width * s.height * 4;
        uint8_t *buffer = (uint8_t *)calloc(bufferLen, 1);
        data = [[JMXUint8ClampedArray uint8ClampedArrayWithBytesNoCopy:buffer
                                                               length:bufferLen
                                                        freeOnRelease:YES] retain];
        self.size = s;
        
    }
    return self;
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}

- (CGFloat)width
{
    return size.width;
}

- (CGFloat)height
{
    return size.height;
}

- (NSUInteger)length
{
    return size.height * size.width * 4;
}

- (const void *)bytes
{
    return (const void *)data.buffer;
}

#pragma mark V8

static v8::Handle<Value>GetData(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXImageData *data = (JMXImageData *)info.Holder()->GetPointerFromInternalField(0);
    JMXUint8ClampedArray *clampedArray = [JMXUint8ClampedArray
                                          uint8ClampedArrayWithBytesNoCopy:(uint8_t *)[data bytes]
                                                                    length:[data length]
                                                             freeOnRelease:NO];
    return handleScope.Close([clampedArray jsObj]);
}

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("ImageData"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("data"), GetData);

    return objectTemplate;
}

static void JMXImageDataJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXImageData *obj = static_cast<JMXImageData *>(parameter);
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
    Handle<FunctionTemplate> objectTemplate = [JMXImageData jsObjectTemplate];
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    jsInstance.MakeWeak([self retain], JMXImageDataJSDestructor);
    return handle_scope.Close(jsInstance);
}

@end

