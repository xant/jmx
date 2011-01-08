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

@interface JMXElement : NSXMLElement {
@private
    BOOL _initialized;
    NSString *uid;
    NSString *jsId;
}

@property (readonly) NSString *uid;
@property (copy) NSString *jsId;

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXElement);

@end
