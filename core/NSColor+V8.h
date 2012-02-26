//
//  NSColor+V8.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

/*!
 @header NSColor+V8.h
 @abstract Encapsultaes an NSColor object
 @discussion Wrapper class for colors inside the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"
#import "JMXCanvasStyle.h"

/*!
 @category NSColor (JMXColor)
 @discussion conforms to protocol: JMXV8
 */
@interface NSColor (JMXColor)  <JMXV8, JMXCanvasStyle>

/*!
 @method r
 @abstract red component
 @return the red component
 */
- (CGFloat) r;

/*!
 @method g
 @return the green component
 @abstract green component
 */
- (CGFloat) g;

/*!
 @method b
 @abstract blue component
 */
- (CGFloat) b;

/*!
 @method a
 @abstract alpha component
 */
- (CGFloat) a;

/*!
 @method w
 @abstract white component
 */
- (CGFloat) w;

/*!
 @method colorFromCSSString:
 @abstract create a color object starting from a css color string
 @param cssString the css color string
 */
+ (id)colorFromCSSString:(NSString *)cssString;

#ifdef __JMXV8__
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args);
#endif
@end
