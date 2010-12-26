//
//  JMXSize.h
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
 @header JMXSize.h
 @abstract Encapsultaes an NSSzie structures
 @discussion Wrapper class for sizes inside the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"

/*!
 @class JMXSize
 @abstract encapsulates an NSSize and represents a size inside the JMX engine
 @discussion conforms to protocols: JMXV8
 */
@interface JMXSize : NSObject <JMXV8> {
@private
    NSSize nsSize;
}

/*!
 @property nsSize
 @abstract the encapsulated NSSize
 */
@property (assign) NSSize nsSize;

/*!
 @method sizeWithNSSize:
 @abstract create a new JMXSize on top of an existing NSSize
 @param size the NSSize to encapsulate
 @return a new JMXSize instance already initialized and pushed into an autorelease pool
 */
+ (id)sizeWithNSSize:(NSSize)size;
/*!
 @method initWithSize:
 @abstract initialize a JMXSize instance with an existing NSSize
 @param size the NSSize to encapsulate
 @return the initialized instance
 */
- (id)initWithNSSize:(NSSize)size;
/*!
 @method width
 @abstract get the width component
 @return the width component
 */
- (CGFloat)width;
/*!
 @method height
 @abstract get the height component
 @return the height component
 */
- (CGFloat)height;
/*!
 @method setWidth:
 @param width the new width
 @abstract set the width component
 */
- (void)setWidth:(CGFloat)width;
/*!
 @method setHeight:
 @param height the new height
 @abstract set the height component
 */
- (void)setHeight:(CGFloat)height;

#pragma mark V8

#ifdef __JMXV8__
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
v8::Handle<v8::Value> JMXSizeJSConstructor(const v8::Arguments& args);
#endif

@end