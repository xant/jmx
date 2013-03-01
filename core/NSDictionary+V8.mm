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
#import "NSNumber+V8.h"
#import "NSString+V8.h"

@implementation NSDictionary (JMXV8)

using namespace v8;

//static v8::Handle<Value> MapSet(Local<String> name, Local<Value> value, const AccessorInfo &info)
//{
//    v8::Locker lock;
//    HandleScope handleScope;
//    NSMutableDictionary *dict = (NSDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);
//    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
//        String::Utf8Value nameStr(name);
//        NSString *key = [NSString stringWithUTF8String:*nameStr];
//        id obj = value->ToObject()->GetAlignedPointerFromInternalField(0);
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

static Handle<Integer> MapQuery(Local<String> property,
                                const AccessorInfo& info) {
    String::Utf8Value key(property);
    NSDictionary *dict = (NSDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);
    NSString *keyString = [NSString stringWithUTF8String:*key];
    if ([dict objectForKey:keyString]) {
        HandleScope scope;
        return scope.Close(Integer::New(None));
    }
    return Handle<Integer>();
}


static Handle<Array> MapEnumerator(const AccessorInfo& info) {
    HandleScope scope;
    
    NSDictionary *dict = (NSDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);

    int size = dict.count;
    
    Local<Array> env = Array::New(size);
    int i = 0;
    for (id value in dict) {
        if ([value respondsToSelector:@selector(jsObj)]) {
            env->Set(i, [value jsObj]);
        } else {
            env->Set(i, [[value description] jsObj]);
        }
        i++;
    }
    
    return scope.Close(env);
}


static v8::Handle<Value> MapGet(Local<String> name, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    NSDictionary *dict = (NSDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);

    if (strcasecmp(*nameStr, "toString") == 0)
        return handleScope.Close(String::NewSymbol("[object Dictionary]"));
    else if (strcasecmp(*nameStr, "valueOf") == 0)
        return handleScope.Close(String::New([[dict description] UTF8String]));
    if (dict && [dict isKindOfClass:[NSDictionary class]]) {
        NSString *key = [NSString stringWithUTF8String:*nameStr];
        id obj = [dict objectForKey:key];
        if ([obj respondsToSelector:@selector(jsObj)])
            return handleScope.Close([obj jsObj]);
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> MapSet(Local<String> name, Local<Value> value, const AccessorInfo &info)
{
    v8::Locker lock;
    HandleScope handleScope;
    NSMutableDictionary *dict = (NSMutableDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);
    if (![dict isKindOfClass:[NSMutableDictionary class]])
        return False();

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (dict && [dict isKindOfClass:[NSMutableDictionary class]]) {
        String::Utf8Value nameStr(name);
        NSString *key = [NSString stringWithUTF8String:*nameStr];
        id obj = (id)value->ToObject()->GetAlignedPointerFromInternalField(0);
        if (obj) {
            [dict setObject:obj forKey:key];
        }
    }
    [pool release];
    return Undefined();
}

static Handle<v8::Boolean> MapDeleter(Local<String> property,
                                      const AccessorInfo& info) {
    v8::Locker lock;
    HandleScope scope;
    
    NSMutableDictionary *dict = (NSMutableDictionary *)info.Holder()->GetAlignedPointerFromInternalField(0);
    if (![dict isKindOfClass:[NSMutableDictionary class]])
        return False();
    
    String::Utf8Value key(property);

    NSString *keyString = [NSString stringWithUTF8String:*key];
    if ([dict objectForKey:keyString]) {
        [dict removeObjectForKey:keyString];
        return True();
    }
    
    return False();
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
    
    instanceTemplate->SetNamedPropertyHandler(MapGet,
                                             MapSet,
                                             MapQuery,
                                             MapDeleter,
                                             MapEnumerator,
                                             Undefined());
    
    classProto->Set("toString", String::NewSymbol("[object Dictionary]"));
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
    jsInstance->SetAlignedPointerInInternalField(0, self);
    //[ctx addPersistentInstance:jsInstance obj:self];
    return handle_scope.Close(jsInstance);
}

@end
