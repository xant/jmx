//
//  JMXVideoCapture.mm
//  JMX
//
//  Created by xant on 12/21/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXVideoCapture.h"
#import "JMXScript.h"

@implementation JMXVideoCapture

@synthesize device;

+ (NSString *)defaultDevice
{
    return nil;
}

+ (NSArray *)availableDevices
{
    return nil;
}

- (void)start
{
    [self activate];
}

- (void)stop
{
    [self deactivate];
}

#pragma mark V8
using namespace v8;
static v8::Persistent<v8::FunctionTemplate> classTemplate;

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length()) {
        v8::Handle<Value> arg = (*args)[0];
        v8::String::Utf8Value value(arg);
        if (*value)
            [self setDevice:[NSString stringWithUTF8String:*value]];
    }
}

static v8::Handle<Value> DefaultDevice(const Arguments& args)
{
    HandleScope handleScope;
    JMXVideoCapture *vc = (JMXVideoCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (vc) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *defaultDevice = [[vc class] defaultDevice];
        v8::Handle<String> deviceName = String::New([defaultDevice UTF8String]);
        [pool release];
        handleScope.Close(deviceName);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> AvailableDevices(const Arguments& args)
{
    HandleScope handleScope;
    JMXVideoCapture *vc = (JMXVideoCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (vc) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *availableDevices = [[vc class] availableDevices];
        v8::Handle<Array> list = v8::Array::New([availableDevices count]);
        for (int i = 0; i < [availableDevices count]; i++)
            list->Set(Number::New(i), String::New([[availableDevices objectAtIndex:i] UTF8String]));
        [pool release];
        handleScope.Close(list);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> SelectDevice(const Arguments& args)
{
    HandleScope handleScope;
    BOOL ret = NO;
    JMXVideoCapture *vc = (JMXVideoCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (vc) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        NSString *device = [NSString stringWithUTF8String:*value];
        vc.device = device;
        if ([vc.device isEqualTo:device])
            ret = YES;
        [pool release];
    }
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value>Start(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> obj = args.Holder();
    JMXVideoCapture *vc = (JMXVideoCapture *)obj->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [vc start];
    [pool drain];
    return v8::Undefined();
}

static v8::Handle<Value>Stop(const Arguments& args)
{
    HandleScope handleScope;
    Local<Object> obj = args.Holder();
    JMXVideoCapture *vc = (JMXVideoCapture *)obj->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [vc stop];
    [pool drain];
    return v8::Undefined();
}

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXVideoCapture ClassTemplate created");
    v8::Persistent<v8::FunctionTemplate> classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);
    classTemplate->SetClassName(String::New("VideoCapture"));
    classTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(Start));
    classProto->Set("stop", FunctionTemplate::New(Stop));
    classProto->Set("selectDevice", FunctionTemplate::New(SelectDevice));
    classProto->Set("availableDevices", FunctionTemplate::New(AvailableDevices));
    classProto->Set("defaultDevice", FunctionTemplate::New(DefaultDevice));
    // accessors to image parameters
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("device"), GetStringProperty, SetStringProperty);
    return classTemplate;
}

@end
