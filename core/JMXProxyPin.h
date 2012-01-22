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

@interface JMXProxyPin : NSProxy <NSCopying> {
    JMXPin *realPin;
    NSString *label;
	NSXMLElement *parent;
    NSXMLElement *proxyNode;
    NSUInteger index;
}

@property (readwrite, assign) NSXMLElement *parent;
@property (readwrite, copy) NSString *label;
@property (readonly) JMXPin *realPin;
@property (assign) NSUInteger index;

- (id)initWithPin:(JMXPin *)pin andLabel:(NSString *)label;
+ (id)proxyPin:(JMXPin *)pin withLabel:(NSString *)label;
@end
