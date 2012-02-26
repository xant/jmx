//
//  JMXPinOwner.h
//  JMX
//
//  Created by Andrea Guzzo on 1/28/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//
/*!
 @header JMXPinOwner.h
 @abstract define a formal protocol for pin owners
 */
#import <Foundation/Foundation.h>

@class JMXPin;
/*!
 @protocol JMXPinOwner
 @abstract formal protocol for classes owning either input or output pins
           (so being either a signal receiver or producer)
 */
@protocol JMXPinOwner
@required
/*!
 @method provideDataToPin:
 @param the pin asking for new data
 */
- (id)provideDataToPin:(JMXPin *)pin;

/*!
 @method receiveData:fromPin:
 @param data The new data which has been received
 @param pin The pin which received the data
 */
- (void)receiveData:(id)data fromPin:(JMXPin *)pin;
@end
