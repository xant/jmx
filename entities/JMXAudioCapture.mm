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
    JMXAudioBuffer *buf = nil;
    @synchronized (self) {
        buf = [[currentBuffer retain] autorelease];
    }
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
static Persistent<FunctionTemplate> classTemplate;

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
    JMXAudioCapture *vc = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (vc) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *defaultDevice = [[vc class] defaultDevice];
        v8::Handle<String> deviceName = String::New([defaultDevice UTF8String]);
        [pool release];
        return handleScope.Close(deviceName);
    }
    return v8::Undefined();
}


// class method to get a list with all available devices
static v8::Handle<Value>AvailableDevices(const Arguments& args)
{
    HandleScope handleScope;
    v8::Handle<Object> holder = args.Holder();
    v8::String::Utf8Value value(holder->ObjectProtoToString());
    JMXAudioCapture *entity = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
    if (entity) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSArray *availableDevices = [[entity class] availableDevices];
        v8::Handle<Array> list = Array::New([availableDevices count]);
        for (int i = 0; i < [availableDevices count]; i++) {
            list->Set(i, String::New([[availableDevices objectAtIndex:i] UTF8String]));
        }
        [pool drain];
        return handleScope.Close(list);
    }
    return v8::Undefined();
}


static v8::Handle<Value> SelectDevice(const Arguments& args)
{
    HandleScope handleScope;
    BOOL ret = NO;
    JMXAudioCapture *vc = (JMXAudioCapture *)args.Holder()->GetPointerFromInternalField(0);
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

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXAudioCapture ClassTemplate created");
    classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);
    classTemplate->SetClassName(String::New("QtAudioCapture"));
    classTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classProto->Set("start", FunctionTemplate::New(Start));
    classProto->Set("stop", FunctionTemplate::New(Stop));
    classProto->Set("availableDevices", FunctionTemplate::New(AvailableDevices));
    classProto->Set("selectDevice", FunctionTemplate::New(SelectDevice));
    classProto->Set("defaultDevice", FunctionTemplate::New(DefaultDevice));

    return classTemplate;
}

@end
