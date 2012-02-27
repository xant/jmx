//
//  NSDictionary+V8.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__

#import "NSDictionary+V8.h"
#import "NSObject+V8.h"

@implementation NSDictionary (JMXV8)

using namespace v8;

//static v8::Handle<Value> MapSet(Local<String> name, Local<Value> value, const AccessorInfo &info)
//{
//    v8::Locker lock;
//    HandleScope handleScope;
//    NSMutableDictionary *dict = (NSDictionary *)info.Holder()->GetPointerFromInternalField(0);
//    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
//        String::Utf8Value nameStr(name);
//        NSString *key = [NSString stringWithUTF8String:*nameStr];
//        id obj = value->ToObject()->GetPointerFromInternalField(0);
//        if (obj) {
//            [dict setObject:obj forKey:
//        }
//    }
//    Local<Object> obj = Local<Object>::Cast(info.Holder()->GetHiddenValue(String::NewSymbol("map")));
//    obj->Set(name, value);
//    
//    
//    return Undefined();
//}

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
    objectTemplate->SetClassName(String::New("Dictionary"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    instanceTemplate->SetNamedPropertyHandler(MapGet);
    /*
    if ([self respondsToSelector:@selector(jsObjectTemplateAddons:)])
        [self jsObjectTemplateAddons:objectTemplate];
     */
    NSDebug(@"NSDictionary objectTemplate created");
    return objectTemplate;
}

static void JMXDictionaryJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    id obj = static_cast<id>(parameter);
    NSDebug(@"V8 WeakCallback (%@) called ", obj);
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXDictionaryJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    //[ctx addPersistentInstance:jsInstance obj:self];
    return handle_scope.Close(jsInstance);
}

@end
