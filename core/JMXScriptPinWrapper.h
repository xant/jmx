//
//  JMXScriptPinWrapper.h
//  JMX
//
//  Created by Andrea Guzzo on 2/1/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXElement.h"
#import "JMXV8.h"

@class JMXScriptEntity;
@class JMXPin;

using namespace v8;

@interface JMXScriptPinWrapper : JMXElement
{
    v8::Persistent<v8::Function> function;
    NSString *statements;
    JMXScriptEntity *scriptEntity;
    JMXPin *virtualPin;
}

//@property (nonatomic, assign) void (^block)();

+ (id)pinWrapperWithName:(NSString *)name
                function:(v8::Persistent<v8::Function>) aFunction
            scriptEntity:(JMXScriptEntity *)entity;


+ (id)pinWrapperWithName:(NSString *)name
              statements:(NSString *)statements
            scriptEntity:(JMXScriptEntity *)entity;

- (id)initWithName:(NSString *)name
          function:(v8::Persistent<v8::Function>) aFunction
      scriptEntity:(JMXScriptEntity *)entity;

- (id)initWithName:(NSString *)name
        statements:(NSString *)statements
      scriptEntity:(JMXScriptEntity *)entity;

- (void)connectToPin:(JMXPin *)pin;

@end