//
//  JMXScriptOutputPin.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

/*!
 @header JMXScriptOutputPin.h
 @abstract JS wrapper class for input pins
 */

#define __JMXV8__ 1

#import "JMXOutputPin.h"
#import "JMXV8.h"

/*!
 @class JMXScriptOutputPin
 @abstract JS wrapper class allowing to create custom output pins
           from javascript.
 */
@interface JMXScriptOutputPin : JMXOutputPin
{
    v8::Persistent<v8::Function> function;
}

/*!
 @property function
 @abstract the javascript function called to produce data on the pin
           (TODO : document the exact behaviour and how/when this function is being called)
 */
@property (assign) v8::Persistent<v8::Function> function;

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXOutputPinJSConstructor(const v8::Arguments& args);

@end
