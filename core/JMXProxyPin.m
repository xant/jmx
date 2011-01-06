//
//  JMXProxyPin.m
//  JMX
//
//  Created by xant on 12/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXProxyPin.h"
#import "JMXPin.h"
#import <Foundation/Foundation.h>

@implementation JMXProxyPin

@synthesize parent, label;

+ (id)proxyPin:(JMXPin *)pin withLabel:(NSString *)label
{
    return [[[self alloc] initWithPin:pin andLabel:label] autorelease];
}

- (id)initWithPin:(JMXPin *)pin andLabel:(NSString *)pinLabel
{
    parent = nil;
    realObject = pin;
    label = (pinLabel && ![pinLabel isEqualTo:@"undefined"]) ? [pinLabel copy] : [pin.label copy];
    return self;
}

- (void)dealloc
{
    if (label)
        [label release];
    [super dealloc];
}

- (void)pinDisconnected:(NSNotification *)notification
{
    NSMutableDictionary *userInfo = [[notification userInfo] mutableCopy];
    if ([userInfo objectForKey:@"inputPin"] == realObject) {
        [userInfo setObject:self forKey:@"inputPin"];
    } else if ([userInfo objectForKey:@"outputPin"] == realObject) {
        [userInfo setObject:self forKey:@"outputPin"];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                        object:self
                                                      userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinDisconnected" object:realObject];

}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation setTarget:realObject];
    [anInvocation invoke];
    // if the proxied pin is being connected, let's register for disconnect notifications 
    // so that we can propagate them for connections made through the proxy-pin
    if ([anInvocation selector] == @selector(connectToPin:) && realObject.connected) {
        JMXPin *destinationPin;
        [anInvocation getArgument:&destinationPin atIndex:2];
        NSDictionary *userInfo;
        if (realObject.direction == kJMXInputPin)
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
        else
            userInfo = [NSDictionary dictionaryWithObjectsAndKeys:self, @"outputPin", destinationPin, @"inputPin", nil];
        
        if (realObject.sendNotifications) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                                object:self
                                                              userInfo:userInfo];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(pinDisconnected:)
                                                         name:@"JMXPinDisconnected"
                                                       object:realObject];
        }
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [realObject methodSignatureForSelector:aSelector];
}

@end
