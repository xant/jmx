//
//  JMXScriptEntity.h
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define __JMXV8__ 1
#import "JMXEntity.h"

@class JMXScript;

@interface JMXScriptEntity : JMXEntity {
@protected
    NSString *code;
    JMXScript *jsContext;
}

@property (copy) NSString *code;
@property (readonly) JMXScript *jsContext;

- (BOOL)exec;
- (void)resetContext;
- (void)hookEntity:(JMXEntity *)entity;

@end
