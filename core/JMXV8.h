//
//  JMXV8.h
//  JMX
//
//  Created by xant on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXV8.h
 @abstract Protocol for V8-aware classes
 */
#import <Cocoa/Cocoa.h>

/*!
 @protocol JMXV8
 @discussion Any native class exported to V8 must conform to this protocol.
             the JMXScript class (which manages bindings between javascript and native instances)
             will expect mapped classes to conform to this protocol.
 */
@protocol JMXV8

#ifdef __JMXV8__
#include <v8.h>

/*!
 @method jsClassTemplate
 @return a V8 Persistent<FunctionTemplate> which represents the prototype for the exported javascript class 
 */
+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate;

@optional

/*!
 @method jsObj
 @return a javascript wrapper object instance
 */
- (v8::Handle<v8::Object>)jsObj;

/*!
 @method jsInit:
 @param argsValue arguments passed to the constructor
 @discussion This message is sent at construction time and can 
             be implemented to make use of possible arguments 
             passed to the constructor from javascript
 @return a javascript wrapper object instance
 */
- (void)jsInit:(NSValue *)argsValue;

#endif

@end
