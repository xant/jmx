//
//  JMXElement.h
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"
#import "NSXMLNode+V8.h"

@class JMXScript;

@interface JMXElement : NSXMLElement {
@private
    NSString *uid;
    NSString *jsId;
    NSLock *idLock;
}

@property (readonly) NSString *uid;
@property (copy) NSString *jsId;

- (void)appendToNode:(id<JMXV8>)owner;

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXElement);

@end
