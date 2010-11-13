//
//  JMXColor.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#ifdef __JMXV8__
#include <v8.h>
#endif


@interface JMXColor : NSColor {
    
}

#pragma mark V8

#ifdef __JMXV8__
+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate;
- (v8::Handle<v8::Object>)jsObj;
#endif
@end

#ifdef __JMXV8__
// declare the JS constructor
v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args);
#endif