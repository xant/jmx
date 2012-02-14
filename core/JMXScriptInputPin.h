//
//  JMXScriptInputPin.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1

#import "JMXInputPin.h"
#import "JMXV8.h"

@interface JMXScriptInputPin : JMXInputPin
{
    v8::Persistent<v8::Function> function;
}

@property (assign) v8::Persistent<v8::Function> function;

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXInputPinJSConstructor(const v8::Arguments& args);
@end