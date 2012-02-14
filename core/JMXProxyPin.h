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
    NSString *label;
	NSXMLElement *parent;
    NSXMLElement *proxyNode;
    NSUInteger index;
    JMXPin *realPin;
    JMXEntity *owner; // weak
}

@property (readwrite, assign) NSXMLElement *parent;
@property (readwrite, copy) NSString *label;
@property (readonly) JMXPin *realPin;
@property (readonly) JMXEntity *owner; // weak
@property (assign) NSUInteger index;

- (id)initWithPin:(JMXPin *)pin label:(NSString *)label owner:(JMXEntity *)owner;
+ (id)proxyPin:(JMXPin *)pin label:(NSString *)label owner:(JMXEntity *)owner;
@end
