//
//  JMXProxyPin.h
//  JMX
//
//  Created by xant on 12/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXPin.h"

@class NSXMLNode;

@interface JMXProxyPin : NSProxy {
    JMXPin *realObject;
    NSString *label;
    NSXMLNode *parent;
}

@property (readwrite, assign) NSXMLNode *parent;
@property (readwrite, copy)NSString *label;
- (id)initWithPin:(JMXPin *)pin andLabel:(NSString *)label;
+ (id)proxyPin:(JMXPin *)pin withLabel:(NSString *)label;
@end
