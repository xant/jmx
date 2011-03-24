//
//  JMXV8PropertyAccessors.cpp
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXV8PropertyAccessors.h"
#import "JMXPin.h"
#import "JMXEntity.h"

using namespace v8;

#pragma mark Accessor-Wrappers 

v8::Handle<Value>GetNumberProperty(Local<String> name, const AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<Value>GetStringProperty(Local<String> name, const AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<Value>GetSizeProperty(Local<String> name, const AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<Value>GetPointProperty(Local<String> name, const AccessorInfo& info)
{
    return GetObjectProperty(name, info);
}

v8::Handle<Value>GetObjectProperty(Local<String> name, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handle_scope;
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    String::Utf8Value value(name);
    NSString *property = [NSString stringWithUTF8String:*value];
    SEL selector = NSSelectorFromString(property);
    if (obj && [obj respondsToSelector:selector]) {
        id output = [obj performSelector:selector];
        if ([output isKindOfClass:[NSString class]]) {
            [pool drain];
            return handle_scope.Close(String::New([(NSString *)output UTF8String], [(NSString *)output length]));
        } else if ([output isKindOfClass:[NSNumber class]]) {
            [pool drain];
            return handle_scope.Close(Number::New([(NSNumber *)output doubleValue]));
        } else if ([output isKindOfClass:[JMXPin class]] || [output isKindOfClass:[JMXEntity class]] || [output isKindOfClass:[JMXSize class]]) {
            return handle_scope.Close([output jsObj]);
        } else {
            // unsupported class
        }
    }
    else 
        NSLog(@"Unknown property %@", property);
    [pool drain];
    return Undefined();
    
}

static inline BOOL _GetProperty(id obj, char *name, void *ret)
{
    Unlocker unlocker;
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *property = [NSString stringWithUTF8String:name];
    SEL selector = NSSelectorFromString(property);
    if (!obj || ![obj respondsToSelector:selector]) {
        NSLog(@"Unknown property %@", property);
        [pool drain];
        return NO;
    }
    NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setSelector:selector];
    [invocation invokeWithTarget:obj];
    [invocation getReturnValue:ret];
    [pool drain];
    return YES;
}

v8::Handle<Value>GetBoolProperty(Local<String> name, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handle_scope;
    BOOL ret = NO;
    String::Utf8Value value(name);
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    if (!_GetProperty(obj, *value, &ret))
        return Undefined();
    return handle_scope.Close(v8::Boolean::New(ret));
}

v8::Handle<Value>GetDoubleProperty(Local<String> name, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handle_scope;
    double ret = 0;
    String::Utf8Value value(name);
    
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    if (!_GetProperty(obj, *value, &ret))
        return Undefined();
    return handle_scope.Close(Number::New(ret));
}

v8::Handle<Value>GetIntProperty(Local<String> name, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handle_scope;
    int ret = 0;
    String::Utf8Value value(name);
    
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    if (!_GetProperty(obj, *value, &ret))
        return Undefined();
    return handle_scope.Close(Integer::New(ret));
}

static inline void _SetProperty(id obj, char *name, id value)
{
    Unlocker unlocker;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *property = [NSString stringWithUTF8String:name];
    NSString *setter = [NSString stringWithFormat:@"set%@:", 
                        [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                         [property substringFromIndex:1]]
                        ];
    SEL selector = NSSelectorFromString(setter);
    if (!obj || ![obj respondsToSelector:selector]) {
        if ([obj respondsToSelector:NSSelectorFromString(property)])
            NSLog(@"ReadOnly property %@", property);
        else
            NSLog(@"Unknown setter %@", setter);
        [pool drain];
        return;
    }
    [obj performSelector:selector withObject:value];
    [pool release];
}

void SetStringProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsString()) {
        NSLog(@"Bad parameter (not string) passed to %s", *nameStr);
        return;
    }
    String::Utf8Value str(value->ToString());
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
         NSString *newValue = [[NSString alloc] initWithUTF8String:*str];
        _SetProperty(obj, *nameStr, newValue);
        [newValue release];
    }
}

void SetNumberProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsNumber()) {
        NSLog(@"Bad parameter (not number) passed to %s", *nameStr);
        return;
    }
    double number = value->NumberValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        NSNumber *newValue = [[NSNumber alloc] initWithDouble:number];
        _SetProperty(obj, *nameStr, newValue);
        [newValue release];
    }
}

void SetBoolProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!(value->IsBoolean() || value->IsNumber())) {
        NSLog(@"Bad parameter (not bool) passed to %s", *nameStr);
        return;
    }
    BOOL newValue = value->BooleanValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        Unlocker unlocker;
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                            [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                             [property substringFromIndex:1]]
                            ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setArgument:&newValue atIndex:0];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [pool release];
    }
}

void SetIntProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsInt32()) {
        NSLog(@"Bad parameter (not int32) passed to %s", *nameStr);
        return;
    }
    int32_t newValue = value->NumberValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        Unlocker unlocker;
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                            [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                             [property substringFromIndex:1]]
                            ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setArgument:&newValue atIndex:0];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [pool release];
    }
}

void SetDoubleProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    if (!value->IsInt32()) {
        NSLog(@"Bad parameter (not int32) passed to %s", *nameStr);
        return;
    }
    double newValue = value->NumberValue();
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        Unlocker unlocker;
        
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        NSString *property = [NSString stringWithUTF8String:*nameStr];
        NSString *setter = [NSString stringWithFormat:@"set%@:", 
                            [NSString stringWithFormat:@"%@%@",[[property substringToIndex:1] capitalizedString],
                             [property substringFromIndex:1]]
                            ];
        SEL selector = NSSelectorFromString(setter);
        if (!obj || ![obj respondsToSelector:selector]) {
            NSLog(@"Unknown setter %@", setter);
            [pool drain];
            return;
        }
        NSMethodSignature *sig = [obj methodSignatureForSelector:selector];
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:sig];
        [invocation setArgument:&newValue atIndex:2];
        [invocation setSelector:selector];
        [invocation invokeWithTarget:obj];
        [pool release];
    }
}

void SetSizeProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    String::Utf8Value str(value->ToString());
    if (!value->IsObject() || strcmp(*str, "[object Size]") != 0) {
        NSLog(@"%s: Bad parameter (%s is not a Size object)", *nameStr, *str);
        return;
    }
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        JMXSize *newSize = (JMXSize *)value->ToObject()->GetPointerFromInternalField(0);
        _SetProperty(obj, *nameStr, newSize);
    }
}

void SetPointProperty(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //Locker lock;
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    String::Utf8Value str(value->ToString());
    if (!value->IsObject() || strcmp(*str, "[object Point]") != 0) {
        NSLog(@"%s: Bad parameter (%s is not a Point object)", *nameStr, *str);
        return;
    }
    id obj = (id)info.Holder()->GetPointerFromInternalField(0);
    {
        JMXPoint *newPoint = (JMXPoint *)value->ToObject()->GetPointerFromInternalField(0);
        _SetProperty(obj, *nameStr, newPoint);
    }
}
