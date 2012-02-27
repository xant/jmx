//
//  NSMutableDictionary+V8.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__

#import "NSMutableDictionary+V8.h"
#import "NSDictionary+V8.h"

@implementation NSMutableDictionary (JMXV8)
using namespace v8;

static v8::Handle<Value> MapSet(Local<String> name, Local<Value> value, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    NSMutableDictionary *dict = (NSMutableDictionary *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (dict && [dict isKindOfClass:[NSMutableDictionary class]]) {
        String::Utf8Value nameStr(name);
        NSString *key = [NSString stringWithUTF8String:*nameStr];
        id obj = (id)value->ToObject()->GetPointerFromInternalField(0);
        if (obj) {
            [dict setObject:obj forKey:key];
        }
    }
    [pool release];
    return Undefined();
}

static v8::Handle<Value> MapGet(Local<String> name, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    NSDictionary *dict = (NSDictionary *)info.Holder()->GetPointerFromInternalField(0);
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        String::Utf8Value nameStr(name);
        NSString *key = [NSString stringWithUTF8String:*nameStr];
        id obj = [dict objectForKey:key];
        if ([obj respondsToSelector:@selector(jsObj)])
            return handleScope.Close([obj jsObj]);
    }
    return handleScope.Close(Undefined());
}

static Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    //objectTemplate->Inherit([NSDictionary jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("MutableDictionary"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    instanceTemplate->SetNamedPropertyHandler(MapGet, MapSet);
    /*
     if ([self respondsToSelector:@selector(jsObjectTemplateAddons:)])
     [self jsObjectTemplateAddons:objectTemplate];
     */
    NSDebug(@"NSDictionary objectTemplate created");
    return objectTemplate;
}
@end
