//
//  JMXAttribute.mm
//  JMX
//
//  Created by xant on 1/5/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXAttribute.h"

JMXV8_EXPORT_NODE_CLASS(JMXAttribute);

using namespace v8;

@implementation JMXAttribute

- (id)jmxInit
{
    return [super initWithKind:NSXMLAttributeKind options:NSXMLNodeOptionsNone];
}

- (id)initWithKind:(NSXMLNodeKind)kind
{
    return [super initWithKind:NSXMLAttributeKind options:NSXMLNodeOptionsNone];
}


- (id)initWithKind:(NSXMLNodeKind)kind options:(NSUInteger)options
{
    return [super initWithKind:NSXMLAttributeKind options:NSXMLNodeOptionsNone];
}

#pragma mark V8

static v8::Handle<Value> GetValue(Local<String> name, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXAttribute *attr = (JMXAttribute *)info.Holder()->GetPointerFromInternalField(0);
    if (attr)
        return handleScope.Close(v8::String::New([[attr stringValue] UTF8String]));
    return handleScope.Close(Undefined());
}

void SetValue(Local<String> name, Local<Value> value, const AccessorInfo& info)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXAttribute *attr = (JMXAttribute *)info.Holder()->GetPointerFromInternalField(0);
    if (!value->IsString()) {
        NSLog(@"Bad parameter (not string) passed to JMXCData.SetData()");
        return;
    }
    String::Utf8Value str(value->ToString());
    Local<Value> ret;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [attr setStringValue:[NSString stringWithUTF8String:*str]];
    [pool drain];
}

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Attr"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("value"), GetValue, SetValue);
    
    if ([self respondsToSelector:@selector(jsObjectTemplateAddons:)])
        [self jsObjectTemplateAddons:objectTemplate];
    NSLog(@"JMXAttribute objectTemplate created");
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXAttribute jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

@end

