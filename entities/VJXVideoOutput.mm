//
//  VJXVideoOutput.m
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#define __VJXV8__ 1
#import "VJXVideoOutput.h"

using namespace v8;

@implementation VJXVideoOutput

@synthesize size;

- (id)initWithSize:(NSSize)screenSize
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.size = [VJXSize sizeWithNSSize:screenSize];    
        [self registerInputPin:@"frame" withType:kVJXImagePin andSelector:@"drawFrame:"];
        [self registerInputPin:@"screenSize" withType:kVJXSizePin andSelector:@"setSize:"];

        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kVJXNumberPin];
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

static void SetWidth(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    HandleScope handleScope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    VJXVideoOutput *voutput = (VJXVideoOutput *)field->Value();
    NSSize newSize = voutput.size.nsSize;
    newSize.width = value->NumberValue();
    [voutput setSize:[VJXSize sizeWithNSSize:newSize]];
}

static void SetHeight(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    HandleScope handleScope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    VJXVideoOutput *voutput = (VJXVideoOutput *)field->Value();
    NSSize newSize = voutput.size.nsSize;
    newSize.height = value->NumberValue();
    [voutput setSize:[VJXSize sizeWithNSSize:newSize]];
}

static v8::Handle<Value>GetWidth(Local<String> name, const AccessorInfo& info)
{
    HandleScope handleScope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    VJXVideoOutput *voutput = (VJXVideoOutput *)field->Value();
    return handleScope.Close(Integer::New(voutput.size.width));
}

static v8::Handle<Value>GetHeight(Local<String> name, const AccessorInfo& info)
{
    HandleScope handleScope;
    v8::Handle<External> field = v8::Handle<External>::Cast(info.Holder()->GetInternalField(0));
    VJXVideoOutput *voutput = (VJXVideoOutput *)field->Value();
    return handleScope.Close(Integer::New(voutput.size.height));
}

+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate
{
    HandleScope handleScope;
    v8::Handle<v8::FunctionTemplate> entityTemplate = [super jsClassTemplate];
    //entityTemplate->SetClassName(String::New("VideoOutput"));
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("width"), GetWidth, SetWidth);
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("height"), GetHeight, SetHeight);
    return handleScope.Close(entityTemplate);
}

@end
