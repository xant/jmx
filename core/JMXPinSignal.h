//
//  JMXPinSignal.h
//  JMX
//
//  Created by xant on 10/18/10.
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
// NOTE : You don't need to use this class directly,
//        it's meant to be used internally by Pin implementations

/*! 
    @header JMXPinSignal.h
    @abstract Signal flowing across pins
 */
#import <Cocoa/Cocoa.h>

/*!
    @class JMXPinSignal
    @abstract Accessory class used to encapsulate signals flowing across pins
 */
@interface JMXPinSignal : NSObject 
{
    id data;
    id sender;
    id receiver;
}

/*!
 @property data
 @abstract The data
 */
@property (retain) id data;

/*!
 @property sender
 @abstract The sender
 */
@property (retain) id sender;

/*!
 @property receiver
 @abstract The receiver
 */
@property (retain) id receiver;

/*!
 @method signalFromSender:receiver:data:
 @abstract convenience constructor for JMXPinSignal instances
 @param sender the sender of the signal
 @param receiver the receiver of the signal
 @param data the data to be signaled
 @return a new initialized signal instance
 */
+ signalFromSender:(id)sender receiver:(id)receiver data:(id)data;

/*!
 @method initWithSender:receiver:data:
 @abstract designated initializer for JMXPinSignal instances
 @param sender the sender of the signal
 @param receiver the receiver of the signal
 @param data the data to be signaled
 @return the initialized signal instance
 */
- (id)initWithSender:(id)sender receiver:(id)receiver data:(id)data;

@end
