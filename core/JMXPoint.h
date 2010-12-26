//
//  JMXPoint.h
//  JMX
//
//  Created by xant on 9/5/10.
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
 @header JMXPoint.h
 @abstract Encapsultaes an NSPoint object
 @discussion Wrapper class for points inside the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"

/*!
 * @class JMXPoint
 * @abstract Encapsulates an NSPoint object
 * @discussion
 */
@interface JMXPoint : NSObject <JMXV8> {
@private
    NSPoint nsPoint;
}

@property (assign) NSPoint nsPoint;

/*!
 @method pointWithNSPoint:
 @abstract create a new JMXPoint by wrapping an existing NSPoint
 @param point the pre-existing NSPoint instance
 @return the newly created point
 */
+ (id)pointWithNSPoint:(NSPoint)point;
/*!
 @method initWithNSPoint:
 @abstract initialize a  JMXPoint by wrapping an existing NSPoint
 @param point the pre-existing NSPoint instance
 @return the initialized point
 */
- (id)initWithNSPoint:(NSPoint)point;
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
v8::Handle<v8::Value> JMXPointJSConstructor(const v8::Arguments& args);
#endif

@end