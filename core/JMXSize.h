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

@interface JMXSize : NSObject <JMXV8> {
@private
    NSSize nsSize;
}

@property (assign) NSSize nsSize;

+ (id)sizeWithNSSize:(NSSize)size;
- (id)initWithNSSize:(NSSize)size;
- (CGFloat)width;
- (CGFloat)height;
- (void)setWidth:(CGFloat)width;
- (void)setHeight:(CGFloat)height;

#pragma mark V8

#ifdef __JMXV8__
v8::Handle<v8::Value> JMXSizeJSConstructor(const v8::Arguments& args);
#endif

@end