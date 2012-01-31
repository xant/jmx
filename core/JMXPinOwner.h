//
//  JMXPinOwner.h
//  JMX
//
//  Created by Andrea Guzzo on 1/28/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JMXPin;

@protocol JMXPinOwner
@required
- (id)provideDataToPin:(JMXPin *)pin;
- (void)receiveData:(id)data fromPin:(JMXPin *)pin;
@end
