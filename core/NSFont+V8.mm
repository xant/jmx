//
//  NSFont+V8.m
//  JMX
//
//  Created by xant on 3/30/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "NSFont+V8.h"
#import "JMXScript.h"
#import "JMXV8PropertyAccessors.h"

JMXV8_EXPORT_CLASS(NSFont);

@implementation NSFont (JMXV8)

#pragma mark -
#pragma mark V8


- (id)jmxInit
{
    return [self init];
}

using namespace v8;

+ (Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Font"));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors to font properties.
    instanceTemplate->SetAccessor(String::NewSymbol("size"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty);
    // TODO - handle flags like bold, underlined, whatever
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], NSFontJSDestructor);
    jsInstance->SetAlignedPointerInInternalField(0, self);
    //[ctx addPersistentInstance:jsInstance obj:self];
    return handle_scope.Close(jsInstance);
}

@end

