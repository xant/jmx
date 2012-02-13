//
//  JMXMouseEvent.m
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXMouseEvent.h"

#import "JMXScript.h"

using namespace v8;

@implementation JMXMouseEvent
@synthesize screenX,
            screenY,
            ctrlKey,
            shiftKey,
            altKey,
            metaKey,
            button,
            relatedTarget;

- (NSInteger)pageX
{
    return self.screenX;
}

- (NSInteger)pageY
{
    return self.screenY;
}

- (NSInteger)clientX
{
    return self.screenX;
}

- (NSInteger)clientY
{
    return self.screenY;
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
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("MouseEvent"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("screenX"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("screenY"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("pageX"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("pageY"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("clientX"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("clientY"), GetIntProperty);
    // TODO - date properties
    
    return objectTemplate;
}

@end
