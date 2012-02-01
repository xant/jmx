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

@interface JMXScriptEntity : JMXEntity {
@protected
    NSString *code;
    JMXScript *jsContext;
    NSThread *executionThread;
}

@property (copy) NSString *code;
@property (readonly) JMXScript *jsContext;
@property (readonly) NSThread *executionThread;

- (BOOL)exec;
- (void)resetContext;
- (void)hookEntity:(JMXEntity *)entity;

@end
