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
    BOOL repeats;
    NSString *statements;
    //void (^block)();
#ifdef __JMXV8__
    v8::Persistent<v8::Function> function;
#endif
}

#ifdef __JMXV8__
@property (nonatomic, assign) v8::Persistent<v8::Function> function;
#endif

@property (nonatomic, readonly) NSTimer *timer;
@property (nonatomic, readonly) BOOL repeats;
@property (nonatomic, copy) NSString *statements;
//@property (nonatomic, assign) void (^block)();

+ (id)scriptTimerWithFireDate:(NSDate *)date
                     interval:(NSTimeInterval)interval
                       target:(id)target
                     selector:(SEL)selector
                       repeats:(BOOL)repeats;

- (id)initWithFireDate:(NSDate *)date
              interval:(NSTimeInterval)interval
                target:(id)target
              selector:(SEL)selector
                repeats:(BOOL)repeats;
@end
