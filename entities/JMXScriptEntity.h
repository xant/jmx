//
//  JMXScriptEntity.h
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"

@class JMXScript;
@class JMXScriptInputPin;
@class JMXScriptOutputPin;

@interface JMXScriptEntity : JMXEntity {
@protected
    NSString *code;
    JMXScript *jsContext;
    NSThread *executionThread;
    NSMutableSet *pinWrappers;
}

@property (copy) NSString *code;
@property (readonly) JMXScript *jsContext;
@property (readonly) NSThread *executionThread;

- (BOOL)exec;
- (void)resetContext;
- (void)hookEntity:(JMXEntity *)entity;

#ifdef __JMXV8__
- (BOOL)wrapPin:(JMXPin *)pin withFunction:(v8::Persistent<v8::Function>)function;

- (JMXScriptInputPin *)registerJSInputPinWithLabel:(NSString *)label
                                        type:(JMXPinType)type
                                    function:(v8::Persistent<v8::Function>)function;
- (JMXScriptOutputPin *)registerJSOutputPinWithLabel:(NSString *)label
                                          type:(JMXPinType)type
                                      function:(v8::Persistent<v8::Function>)function;
#endif

@end
