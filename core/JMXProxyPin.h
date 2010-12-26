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
    NSString *name;
    NSXMLNode *parent;
}

@property (readwrite, assign) NSXMLNode *parent;
@property (readwrite, copy)NSString *name;
- (id)initWithPin:(JMXPin *)pin andName:(NSString *)name;
+ (id)proxyPin:(JMXPin *)pin withName:(NSString *)name;
@end
