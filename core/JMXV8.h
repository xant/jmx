//
//  JMXV8.h
//  JMX
//
//  Created by xant on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol JMXV8

#ifdef __JMXV8__
#include <v8.h>

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate;

@optional

- (v8::Handle<v8::Object>)jsObj;
- (void)jsInit:(NSValue *)argsValue;

#endif

@end
