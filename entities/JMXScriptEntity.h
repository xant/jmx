//
//  JMXScriptEntity.h
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#define __JMXV8__ 1
#import "JMXThreadedEntity.h"

@interface JMXScriptEntity : JMXEntity {
    NSString *code; 
}

@property (copy) NSString *code;

@end
