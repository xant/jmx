//
//  JMXAudioCapture.mm
//  JMX
//
//  Created by xant on 12/20/10.
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

#import "JMXAudioBuffer.h"
#define __JMXV8__
#import "JMXAudioCapture.h"

@implementation JMXAudioCapture

@synthesize device;

+ (NSArray *)availableDevices
{
    return [NSArray array];
}

+ (NSString *)defaultDevice
{
    return nil;
}

- (id)init
{
    self = [super init];
    if (self) {
        outputPin = [self registerOutputPin:@"audio" withType:kJMXAudioPin];
        // Set the client format to 32bit float data
        // Maintain the channel count and sample rate of the original source format
        outputFormat.mSampleRate = 44100;
        outputFormat.mChannelsPerFrame = 2  ;
        outputFormat.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        outputFormat.mFormatID = kAudioFormatLinearPCM;
        outputFormat.mBytesPerPacket = 4 * outputFormat.mChannelsPerFrame;
        outputFormat.mFramesPerPacket = 1;
        outputFormat.mBytesPerFrame = 4 * outputFormat.mChannelsPerFrame;
        outputFormat.mBitsPerChannel = 32;
        deviceSelect = [self registerInputPin:@"device" 
                                     withType:kJMXStringPin 
                                  andSelector:@"setDevice:"
                                allowedValues:[[self class] availableDevices]
                                 initialValue:[[self class] defaultDevice]];
    } else {
        [self dealloc];
        return nil;
    }
    return self;
}

- (JMXAudioBuffer *)currentBuffer
{
    static OSSpinLock lock;
    JMXAudioBuffer *buf = nil;
    OSSpinLockLock(&lock);
    buf = [[currentBuffer retain] autorelease];
    OSSpinLockUnlock(&lock);
    return buf;
}

- (void)tick:(uint64_t)timeStamp
{
    [self outputDefaultSignals:timeStamp];
}

- (void)start
{
}

- (void)stop
{
}

#pragma mark V8
using namespace v8;
// the following global is usually defined by the JMXV8_EXPORT_ENTITY_CLASS() macro
// but we don't want to use it because we don't want to implement a constructor in the native language
static Persistent<FunctionTemplate> objectTemplate;

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

static v8::Handle<Value>Start(const Arguments& args)
{
    HandleScope handleScope;
    JMXAudioCapture *entity = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (entity)
        [entity start];
    return v8::Undefined();
}

static v8::Handle<Value>Stop(const Arguments& args)
{
    HandleScope handleScope;
    JMXAudioCapture *entity = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (entity)
        [entity stop];
    return v8::Undefined();
}

static v8::Handle<Value> DefaultDevice(const Arguments& args)
{
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *defaultDevice = nil;
    JMXAudioCapture *ac = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (ac) {
        defaultDevice = [[ac class] defaultDevice];
    } else {
        Class objcClass = (Class)External::Cast(*(args.Holder()->Get(String::NewSymbol("_objcClass"))))->Value();
        defaultDevice = [objcClass defaultDevice];
    }
    v8::Handle<String> deviceName = String::New([defaultDevice UTF8String]);
    [pool release];
    return handleScope.Close(deviceName);
}


// class method to get a list with all available devices
static v8::Handle<Value> AvailableDevices(const Arguments& args)
{
    HandleScope handleScope;
    NSArray *availableDevices = nil;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXAudioCapture *ac = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (ac) { // called as instance method
        availableDevices = [[ac class] availableDevices];
    } else { // called as class method
        Class objcClass = (Class)External::Cast(*(args.Holder()->Get(String::NewSymbol("_objcClass"))))->Value();
        availableDevices = [objcClass availableDevices];
    }
    v8::Handle<Array> list = v8::Array::New((int)[availableDevices count]);
    for (int i = 0; i < [availableDevices count]; i++) {
        list->Set(Number::New(i), String::New([[availableDevices objectAtIndex:i] UTF8String]));
    }
    [pool release];
    return handleScope.Close(list);
}

static v8::Handle<Value> SelectDevice(const Arguments& args)
{
    HandleScope handleScope;
    BOOL ret = NO;
    JMXAudioCapture *ac = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (ac) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        v8::Handle<Value> arg = args[0];
        v8::String::Utf8Value value(arg);
        NSString *device = [NSString stringWithUTF8String:*value];
        ac.device = device;
        if ([ac.device isEqualTo:device])
            ret = YES;
        [pool release];
    }
    return handleScope.Close(v8::Boolean::New(ret));
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    NSDebug(@"JMXAudioCapture objectTemplate created");
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("QtAudioCapture"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(Start));
    classProto->Set("stop", FunctionTemplate::New(Stop));
    classProto->Set("availableDevices", FunctionTemplate::New(AvailableDevices));
    classProto->Set("selectDevice", FunctionTemplate::New(SelectDevice));
    classProto->Set("defaultDevice", FunctionTemplate::New(DefaultDevice));

    return objectTemplate;
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    [super jsRegisterClassMethods:constructor]; // let our super register its methods (if any)
    constructor->Set("availableDevices", FunctionTemplate::New(AvailableDevices));
    constructor->Set("defaultDevice", FunctionTemplate::New(DefaultDevice));
}

@end
