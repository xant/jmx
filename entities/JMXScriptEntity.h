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
@class JMXScriptPinWrapper;
@class JMXScriptFile;

@interface JMXScriptEntity : JMXEntity {
@protected
    NSMutableString *code;
    JMXScript *jsContext;
    NSThread *executionThread;
    NSMutableSet *pinWrappers;
    JMXOutputPin *codeOutputPin;
    NSArray *arguments;
}

@property (copy) NSString *code;
@property (retain) NSArray *arguments; // XXX - arguments need to be set before code
@property (readonly) JMXScript *jsContext;
@property (readonly) NSThread *executionThread;

- (BOOL)exec;
- (BOOL)exec:(NSString *)code;
- (void)resetContext;
- (void)hookEntity:(JMXEntity *)entity;
- (JMXScriptFile *)load:(NSString *)path;

#ifdef __JMXV8__
- (JMXScriptPinWrapper *)wrapPin:(JMXPin *)pin withFunction:(v8::Persistent<v8::Function>)function;

- (JMXScriptInputPin *)registerJSInputPinWithLabel:(NSString *)label
                                        type:(JMXPinType)type
                                    function:(v8::Persistent<v8::Function>)function;
- (JMXScriptOutputPin *)registerJSOutputPinWithLabel:(NSString *)label
                                          type:(JMXPinType)type
                                      function:(v8::Persistent<v8::Function>)function;
#endif

@end
