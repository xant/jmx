//
//  JMXKeyboardEvent.mm
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXKeyboardEvent.h"
#import "JMXScript.h"

using namespace v8;
@implementation JMXKeyboardEvent
@synthesize str,
            key,
            locale,
            ctrlKey,
            shiftKey,
            altKey,
            metaKey,
            repeat;

- (NSString *)char
{
    return self.str;
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
    objectTemplate->SetClassName(String::New("KeyboardEvent"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("char"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("key"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("locale"), GetStringProperty);
    // TODO - date properties
    
    return objectTemplate;
}

@end

