//
//  JMXColor.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXColor.h
 @abstract Encapsultaes an NSColor object
 @discussion Wrapper class for points inside the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"
#import "JMXCanvasStyle.h"

/* TODO - should be a category */

/*!
 @class JMXColor
 @discussion conforms to protocols: JMXV8
 */
@interface NSColor (JMXColor) < JMXV8, JMXCanvasStyle > 

/*!
 @property r
 @abstract red component
 */
@property (readonly) CGFloat r;
/*!
 @property g
 @abstract green component
 */
@property (readonly) CGFloat g;
/*!
 @property b
 @abstract blue component
 */
@property (readonly) CGFloat b;
/*!
 @property a
 @abstract alpha component
 */
@property (readonly) CGFloat a;

@property (readonly) CGFloat w;

+ (id)colorFromCSSString:(NSString *)cssString;

#ifdef __JMXV8__
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args);
#endif
@end
