//
//  JMXScriptTimer.h
//  JMX
//
//  Created by Andrea Guzzo on 1/22/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@interface JMXScriptTimer : NSObject <JMXV8> {
@private
    NSTimer *timer;
#ifdef __JMXV8__
    v8::Persistent<v8::Function> function;
#endif
}

#ifdef __JMXV8__
@property (nonatomic, assign) v8::Persistent<v8::Function> function;
#endif
@property (nonatomic, readonly) NSTimer *timer;

+ (id)scriptTimerWithFireDate:(NSDate *)date interval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector;
- (id)initWithFireDate:(NSDate *)date interval:(NSTimeInterval)interval target:(id)target selector:(SEL)selector;
@end
