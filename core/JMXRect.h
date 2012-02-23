//
//  JMXRect.h
//  JMX
//
//  Created by xant on 1/17/11.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//
/*!
 @header JMXRect.h
 @abstract Encapsultaes an NSRect object
 @discussion Wrapper class for Rects inside the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"

/*!
 * @class JMXRect
 * @abstract Encapsulates an NSRect object
 * @discussion
 */
@interface JMXRect : NSObject <JMXV8> {
@private
    NSRect nsRect;
}

/*!
 @property neRect the underlying NSRect structure
 */
@property (assign) NSRect nsRect;

/*!
 @method rectWithNSRect:
 @abstract create a new JMXRect by wrapping an existing NSRect
 @param Rect the pre-existing NSRect instance
 @return the newly created Rect
 */
+ (id)rectWithNSRect:(NSRect)Rect;
/*!
 @method initWithNSRect:
 @abstract initialize a  JMXRect by wrapping an existing NSRect
 @param Rect the pre-existing NSRect instance
 @return the initialized Rect
 */
- (id)initWithNSRect:(NSRect)Rect;
/*!
 @method x
 @abstract get the x coordinate
 @return the x coordinate
 */
- (CGFloat)x;
/*!
 @method y
 @abstract get the y coordinate
 @return the y coordinate
 */
- (CGFloat)y;

#ifdef __JMXV8__
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXRectJSConstructor(const v8::Arguments& args);
#endif

@end