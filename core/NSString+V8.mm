//
//  NSObject+V8.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//
#define __JMXV8__
#import "NSString+V8.h"

@implementation NSString (JMXV8)

#pragma mark V8

using namespace v8;

- (v8::Handle<v8::String>)jsObj
{
    HandleScope handle_scope;
    return handle_scope.Close(String::New([(NSString *)self UTF8String], (int)[(NSString *)self length]));
}

@end
