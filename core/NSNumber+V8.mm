//
//  NSObject+V8.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//
#define __JMXV8__
#import "NSNumber+V8.h"

@implementation NSNumber (JMXV8)

#pragma mark V8

using namespace v8;

- (v8::Handle<v8::Number>)jsObj
{
    HandleScope handle_scope;
    return handle_scope.Close(v8::Number::New([self doubleValue]));
}

@end
