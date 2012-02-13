//
//  JMXOutputPin.h
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

/*!
 @header JMXInputPin.h
 @abstract Input Pin
 */ 
#import <Cocoa/Cocoa.h>
#import "JMXPin.h"

@class JMXInputPin;

/*!
 @class JMXOutputPin
 @abstract concrete class for output pins
 */
@interface JMXOutputPin : JMXPin {
    NSMutableDictionary *receivers;

}

/*!
 @property receivers
 @abstract array containing all input pins currently connected to this output pin
 */
@property (readonly)  NSDictionary *receivers;

/*!
 @method attachObject:withSelector:
 @abstract connect any kind of object as receiver of the signal
 @param pinReceiver an object which will receive the signal each time it's delivered
 @param pinSignal the signature of the selector to perform when the signal arrives
 */
- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal;
/*!
 @method detachObject:
 @abstract detach an object so that it won't receive signals anymore
 @param pinReceiver the object we want to detach
 @discussion this method does nothing if the passed pin is not connected to us (so not in <code>producers</code>
 */
- (void)detachObject:(id)pinReceiver;
/*!
 @method connectToPin:
 @param destinationPin the input pin which wants to connect
 @return YES on success, NO otherwise
 */
- (BOOL)connectToPin:(JMXInputPin *)destinationPin;
/*!
 @method disconnectFromPin:
 @param destinationPin
 @abstract remove a connected pin
 @discussion this method does nothing if the passed pin is not connected to us (so not in <code>producers</code>
 */
- (void)disconnectFromPin:(JMXInputPin *)destinationPin;

@end
