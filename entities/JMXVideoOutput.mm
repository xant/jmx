//
//  JMXVideoOutput.m
//  JMX
//
//  Created by xant on 9/2/10.
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

#define __JMXV8__ 1
#import "JMXVideoOutput.h"

using namespace v8;

@implementation JMXVideoOutput

@synthesize size;

- (id)initWithSize:(NSSize)screenSize
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.size = [JMXSize sizeWithNSSize:screenSize];
        [self registerInputPin:@"frame" withType:kJMXImagePin andSelector:@"drawFrame:"];
        [self registerInputPin:@"frameSize" withType:kJMXSizePin andSelector:@"setSize:"];

        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kJMXNumberPin];
        self.name = @"VideoOutput";
    }
    return self;
}

- (id)init
{
    NSSize defaultSize = { 640, 480 };
    return [self initWithSize:defaultSize];
}

- (void)drawFrame:(CIImage *)frame
{
    @synchronized(self) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [frame retain];
    }
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    self.size = nil;
    [super dealloc];
}

#pragma mark V8

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

static void SetWidth(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXVideoOutput *voutput = (JMXVideoOutput *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSSize newSize = voutput.size.nsSize;
    newSize.width = value->NumberValue();
    [voutput setSize:[JMXSize sizeWithNSSize:newSize]];
    [pool drain];
}

static void SetHeight(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXVideoOutput *voutput = (JMXVideoOutput *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSSize newSize = voutput.size.nsSize;
    newSize.height = value->NumberValue();
    [voutput setSize:[JMXSize sizeWithNSSize:newSize]];
    [pool release];
}

static v8::Handle<Value>GetWidth(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXVideoOutput *voutput = (JMXVideoOutput *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(Integer::New(voutput.size.width));
}

static v8::Handle<Value>GetHeight(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXVideoOutput *voutput = (JMXVideoOutput *)info.Holder()->GetPointerFromInternalField(0);
    return handleScope.Close(Integer::New(voutput.size.height));
}

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    /*
    if (!classTemplate.IsEmpty())
        return classTemplate;*/
    v8::Persistent<FunctionTemplate> classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);  
    classTemplate->SetClassName(String::New("VideoOutput"));
    classTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("width"), GetWidth, SetWidth);
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("height"), GetHeight, SetHeight);
    NSLog(@"JMXVideoOutput ClassTemplate created");
    return classTemplate;
}

@end
