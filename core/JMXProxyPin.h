//
//  JMXProxyPin.h
//  JMX
//
//  Created by xant on 12/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXProxyPin.h
 @abstract Proxy Pin
 */ 
#import <Cocoa/Cocoa.h>
#import "JMXPin.h"

@class NSXMLNode;

/*!
 @class JMXProxyPin
 @abstract create a new 'virtual' pin which encapsulates an existing pin 
            (eventually hidden or belonging to an internally managed entity)
            and allow using it to create new connections
            TODO : document the typical usage pattern (script-based entities exposing pins for their subentities)
 */
@interface JMXProxyPin : NSProxy <NSCopying> {
    NSString *label;
	NSXMLElement *parent;
    NSXMLElement *proxyNode;
    NSUInteger index;
    JMXPin *realPin;
    JMXEntity *owner; // weak
}

/*!
 @property parent
 @abstract our parent in the DOM hierarchy
 */
@property (readwrite, assign) NSXMLElement *parent;

/*!
 @property label
 @abstract the mnemonic label assigned to this entity
 */
@property (readwrite, copy) NSString *label;

/*!
 @property realPin
 @abstract the underlying real pin
 */
@property (readonly) JMXPin *realPin;

/*!
 @property owner
 @abstract weak reference to the owner of this pin (usually an entity ... but could really be any kind of object)
 */
@property (readonly) JMXEntity *owner; // weak

/*!
 @method proxyPin:label:owner:
 @abstract convenience constructor for proxypins given the real pin to proxy,  an owner and a label
 @param pin the underlying pin which needs to be proxied
 @param label the label to assign to the virtual pin
 @param owner the owner of the new virtual pin
 */
+ (id)proxyPin:(JMXPin *)pin label:(NSString *)label owner:(JMXEntity *)owner;

/*!
 @method initWithPin:label:owner:
 @abstract designated initializer
 @param pin the underlying pin which needs to be proxied
 @param label the label to assign to the virtual pin
 @param owner the owner of the new virtual pin
 */
- (id)initWithPin:(JMXPin *)pin label:(NSString *)label owner:(JMXEntity *)owner;
@end
