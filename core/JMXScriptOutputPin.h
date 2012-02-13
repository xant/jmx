//
//  JMXScriptOutputPin.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1

#import "JMXOutputPin.h"
#import "JMXV8.h"

@interface JMXScriptOutputPin : JMXOutputPin
{
    v8::Persistent<v8::Function> function;
}

@property (assign) v8::Persistent<v8::Function> function;

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXOutputPinJSConstructor(const v8::Arguments& args);

@end
