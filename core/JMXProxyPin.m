//
//  JMXProxyPin.m
//  JMX
//
//  Created by xant on 12/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXProxyPin.h"
#import "JMXPin.h"
#import "JMXAttribute.h"
#import <Foundation/Foundation.h>

@implementation JMXProxyPin

@synthesize parent, label, realPin, index, owner;

+ (id)proxyPin:(JMXPin *)pin label:(NSString *)label owner:(JMXEntity *)anEntity
{
    return [[[self alloc] initWithPin:pin label:label owner:anEntity] autorelease];
}

- (id)initWithPin:(JMXPin *)pin label:(NSString *)pinLabel owner:(JMXEntity *)anEntity
{
    parent = nil;
    owner = anEntity;
    realPin = pin;//[pin retain];
    label = (pinLabel && ![pinLabel isEqualTo:@"undefined"]) ? [pinLabel copy] : [pin.label copy];
    index = 0;
    proxyNode = [[JMXElement alloc] initWithName:@"JMXProxyPin"];
    [proxyNode addAttribute:[JMXAttribute attributeWithName:@"pin" stringValue:pin.uid]];
    [proxyNode addAttribute:[JMXAttribute attributeWithName:@"label" stringValue:label]];

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinDisconnected" object:realPin];
    [label release];
    //[realPin release];
    [proxyNode detach];
    [proxyNode release];
    [super dealloc];
}

- (void)pinDisconnected:(NSNotification *)notification
{
    NSMutableDictionary *userInfo = [[notification userInfo] mutableCopy];
    if ([userInfo objectForKey:@"inputPin"] == realPin) {
        [userInfo setObject:self forKey:@"inputPin"];
    } else if ([userInfo objectForKey:@"outputPin"] == realPin) {
        [userInfo setObject:self forKey:@"outputPin"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                        object:self
                                                      userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinDisconnected" object:realPin];

}


- (BOOL)isKindOfClass:(Class)aClass
{
    if (realPin)
        return [realPin isKindOfClass:aClass];
    return NO;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    @synchronized(self) {
        if (!realPin)
            return;
    }

    // otherwise we need to determine if we want to forward the invocation
    // to either the underlying pin or the fake xml node
    if ([proxyNode respondsToSelector:[anInvocation selector]])
        [anInvocation setTarget:proxyNode];
    else
        [anInvocation setTarget:realPin];
    [anInvocation invoke];
    // if the proxied pin is being connected, let's register for disconnect notifications 
    // so that we can propagate them for connections made through the proxy-pin
    if ([anInvocation selector] == @selector(connectToPin:) && realPin.connected) {
        JMXPin *destinationPin;
        [anInvocation getArgument:&destinationPin atIndex:2];
        NSDictionary *userInfo;
        if (realPin.direction == kJMXInputPin)
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
        else
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"outputPin", destinationPin, @"inputPin", nil];
        
        if (realPin.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                                object:self
                                                              userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(pinDisconnected:)
                                                         name:@"JMXPinDisconnected"
                                                       object:realPin];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [realPin methodSignatureForSelector:aSelector];
}

- (id)copyWithZone:(NSZone *)zone
{
    return [self retain];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"JMXProxyPin:%@", label];
}

@end
