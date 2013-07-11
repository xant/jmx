//
//  JMXApplicationDelegate.h
//  JMX
//
//  Created by xant on 7/11/13.
//  Copyright (c) 2013 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JMXApplicationDelegate <NSApplicationDelegate>

@required
- (void)logMessage:(NSString *)message, ...;
- (void)logMessage:(NSString *)message args:(va_list)args;

@end