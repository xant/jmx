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

#import <Cocoa/Cocoa.h>
#ifdef __JMXV8__
#include <v8.h>
#endif

@interface JMXPoint : NSObject {
@private
    NSPoint nsPoint;
}

@property (assign) NSPoint nsPoint;

+ (id)pointWithNSPoint:(NSPoint)point;
- (id)initWithNSPoint:(NSPoint)point;
- (CGFloat)x;
- (CGFloat)y;

#pragma mark V8

#ifdef __JMXV8__
+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate;
- (v8::Handle<v8::Object>)jsObj;
//JMXV8_DECLARE_CONSTRUCTOR(JMXPin);
#endif

@end

#ifdef __JMXV8__
// declare the JS constructor
v8::Handle<v8::Value> JMXPointJSConstructor(const v8::Arguments& args);
#endif