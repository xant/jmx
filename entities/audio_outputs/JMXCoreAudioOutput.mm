//
//  JMXCoreAudioOutput.m
//  JMX
//
//  Created by xant on 9/16/10.
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

#import "JMXAudioDevice.h"
#define __JMXV8__
#import "JMXCoreAudioOutput.h"
#include "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXCoreAudioOutput);

@implementation JMXCoreAudioOutput

+ (NSArray *)availableDevices
{
    NSMutableArray *devicesList = [[NSMutableArray alloc] init];
    NSArray *availableDevices = [JMXAudioDevice outputDevices];
    for (JMXAudioDevice *dev in availableDevices)
        [devicesList addObject:[dev deviceUID]];
    return availableDevices;
}

- (id)init
{
    outputDevice = [[JMXAudioDevice defaultOutputDevice] retain];
    [outputDevice setIOTarget:self 
                 withSelector:@selector(provideSamplesToDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:)
               withClientData:self];
    format = [[outputDevice streamDescriptionForChannel:0 forDirection:kJMXAudioOutput] retain];
    [outputDevice setDelegate:(JMXCoreAudioOutput *)self];
    deviceSelect = [self registerInputPin:@"device"
                                              withType:kJMXStringPin
                                           andSelector:@"setDevice"
                                         allowedValues:[JMXCoreAudioOutput availableDevices]
                                          initialValue:[outputDevice deviceUID]];
    [super init]; // we know that our parent won't never return nil and we need
                  // its initializer to be run after we have set the format
    // start the device
    [outputDevice deviceStart];
    return self;
}

- (void)dealloc
{
    if (outputDevice) {
        [outputDevice release];
    }
    [super dealloc];
}

- (void)setDevice:(NSString *)deviceUID
{
    if (outputDevice && ![deviceUID isEqualTo:[outputDevice deviceUID]]) {
        JMXAudioDevice *newDevice = [JMXAudioDevice deviceWithUID:deviceUID];
        if (newDevice) {
            @synchronized(self) {
                [outputDevice deviceStop];
                [outputDevice release];
                outputDevice = [newDevice retain];
                [outputDevice deviceStart];
            }
        }
    }
}

- (void)provideSamplesToDevice:(JMXAudioDevice *)device
                     timeStamp:(AudioTimeStamp *)timeStamp
                     inputData:(AudioBufferList *)inInputData
                     inputTime:(AudioTimeStamp *)inInputTime
                    outputData:(AudioBufferList *)outOutputData
                    outputTime:(AudioTimeStamp *)inOutputTime
                    clientData:(JMXCoreAudioOutput *)clientData

{
    JMXAudioBuffer *sample = [self currentSample];
    if (sample) {
        int i;
        for (i = 0; i < outOutputData->mNumberBuffers; i++) {
            SInt32 bytesToCopy = MIN(outOutputData->mBuffers[i].mDataByteSize, sample.bufferList->mBuffers[i].mDataByteSize);
            if (outOutputData->mBuffers[i].mData && sample.bufferList->mNumberBuffers > i) {
                bcopy(sample.bufferList->mBuffers[i].mData,
                      outOutputData->mBuffers[i].mData,
                       bytesToCopy);
                outOutputData->mBuffers[i].mDataByteSize = bytesToCopy;
                outOutputData->mBuffers[i].mNumberChannels = sample.bufferList->mBuffers[i].mNumberChannels;
            }
        }
        [currentSamplePin deliverData:sample fromSender:self];
    } else {
        //NSLog(@"NO FRAME");
    }
}

- (void)audioDeviceClockSourceDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
}

- (void)audioDeviceSomethingDidChange:(JMXAudioDevice *)device
{
}

- (void)audioDeviceDidOverload:(JMXAudioDevice *)device
{
    NSLog(@"Overload!");
}

#pragma mark V8
using namespace v8;

// class method to get a list with all available devices
static v8::Handle<Value>availableFilters(const Arguments& args)
{
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *availableDevices = [JMXCoreAudioOutput availableDevices];
    v8::Handle<Array> list = Array::New([availableDevices count]);
    for (int i = 0; i < [availableDevices count]; i++) {
        list->Set(i, String::New([[availableDevices objectAtIndex:i] UTF8String]));
    }
    [pool drain];
    return handleScope.Close(list);
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    v8::Persistent<FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);  
    objectTemplate->SetClassName(String::New("CoreAudioOutput"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("availableFilters", FunctionTemplate::New(availableFilters));
    NSLog(@"JMXCoreAudioOutput objectTemplate created");
    return objectTemplate;
}

@end
