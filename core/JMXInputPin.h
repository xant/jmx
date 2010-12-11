//
//  JMXInputPin.h
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

@class JMXOutputPin;

/*!
 @class JMXInputPin
 @abstract concrete class for input pins
 */
@interface JMXInputPin : JMXPin {
    NSMutableArray      *producers;
}
/*!
 @property producers
 @abstract array containing all output pins currently connected to this input pin
 */
@property (readonly)  NSArray *producers;

/*!
 @method readProducers
 @return NSArray containing data from all connected producers
 */
- (NSArray *)readProducers;
/*!
 @method moveProducerFromIndex:toIndex:
 @param src source index in the <code>producers</code> array
 @param dst destination index
 @return YES on success, NO otherwise
 */
- (BOOL)moveProducerFromIndex:(NSUInteger)src toIndex:(NSUInteger)dst;
/*!
 @method connectToPin:
 @param destinationPin the output pin which wants to connect
 @return YES on success, NO otherwise
 */
- (BOOL)connectToPin:(JMXOutputPin *)destinationPin;
/*!
 @method disconnectFromPin:
 @param destinationPin
 @abstract remove a connected pin
 @discussion this method does nothing if the passed pin is not connected to us (so not in @link producers @/link
 */
- (void)disconnectFromPin:(JMXOutputPin *)destinationPin;
@end
