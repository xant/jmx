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
#import "JMXAttribute.h"

@implementation JMXVideoOutput

@synthesize size, backgroundColor;

- (id)initWithSize:(NSSize)screenSize
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.size = [JMXSize sizeWithNSSize:screenSize];
        [self registerInputPin:@"frame" withType:kJMXImagePin andSelector:@"drawFrame:"];
        [self registerInputPin:@"frameSize" withType:kJMXSizePin andSelector:@"setSize:"];
        [self addAttribute:[JMXAttribute attributeWithName:@"width"
                                               stringValue:[NSString stringWithFormat:@"%.0f", screenSize.width]]];
        [self addAttribute:[JMXAttribute attributeWithName:@"height"
                                               stringValue:[NSString stringWithFormat:@"%.0f", screenSize.height]]];
        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kJMXNumberPin];
        self.label = @"VideoOutput";
        self.backgroundColor = [NSColor colorWithDeviceRed:1.0 green:1.0 blue:1.0 alpha:1.0];
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

- (JMXSize *)size
{
    @synchronized(self) {
        return [[size retain] autorelease];
    }
}

- (void)setSize:(JMXSize *)newSize
{
    @synchronized(self) {
        if ([size isEqualTo:newSize])
            return;
        [size release];
        if (newSize)
            size = [newSize retain];
        else
            size = nil;
        NSXMLNode *widthAttr = [self attributeForName:@"width"];
        NSXMLNode *heightAttr = [self attributeForName:@"height"];

        [widthAttr setStringValue:[NSString stringWithFormat:@"%.0f", size.width]];
        [heightAttr setStringValue:[NSString stringWithFormat:@"%.0f", size.height]];
    }
}

#pragma mark V8
using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

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

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    v8::Persistent<FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);  
    objectTemplate->SetClassName(String::New("VideoOutput"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("width"), GetWidth, SetWidth);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("height"), GetHeight, SetHeight);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("size"), GetSizeProperty, SetSizeProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("backgroundColor"), GetColorProperty, SetColorProperty);

    NSDebug(@"JMXVideoOutput objectTemplate created");
    return objectTemplate;
}

@end
