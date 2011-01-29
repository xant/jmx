//
//  JMXImageElement.mm
//  JMX
//
//  Created by xant on 1/18/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXImageElement.h"
#import "JMXScript.h"

JMXV8_EXPORT_CLASS(JMXImageElement)

@implementation JMXImageElement

#pragma mark V8

using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Canvas"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("alt"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("src"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("useMap"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("isMap"), GetBoolProperty, SetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetIntProperty, SetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetIntProperty, SetIntProperty);

    
    NSLog(@"JMXImageElement objectTemplate created");
    return objectTemplate;
}

@end
