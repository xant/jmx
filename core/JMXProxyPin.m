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

+ (id)proxyPin:(JMXPin *)pin withName:(NSString *)name
{
    return [[[self alloc] initWithPin:pin andName:name] autorelease];
}

- (id)initWithPin:(JMXPin *)pin andName:(NSString *)pinName
{
    realObject = pin;
    overriddenName = (pinName && ![pinName isEqualTo:@"undefined"]) ? [pinName copy] : [pin.name copy];
    return self;
}

- (void)dealloc
{
    if (overriddenName)
        [overriddenName release];
    [super dealloc];
}

- (NSString *)name
{
    return overriddenName;
}

- (void)setName:(NSString *)pinName
{
    if (overriddenName)
        [overriddenName release];
    overriddenName = [pinName copy];
}

- (void)pinDisconnected:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    /* TODO - update userInfo to reference the proxied instance
    JMXPin *inputPin = [userInfo objectForKey:@"inputPin"];
    JMXPin *outputPin = [userInfo objectForKey:@"outputPin"];
     */
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                        object:self
                                                      userInfo:userInfo];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"JMXPinDisconnected" object:realObject];

}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    if ([anInvocation selector] == @selector(name) ||
        [anInvocation selector] == @selector(setName:))
    {
        [anInvocation setTarget:self];
    } else {
        if ([anInvocation selector] == @selector(connectToPin:)) {
            JMXPin *destinationPin;
            [anInvocation getArgument:&destinationPin atIndex:2];
            NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
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
        [anInvocation setTarget:realObject];
    }
    [anInvocation invoke];
    return;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [realObject methodSignatureForSelector:aSelector];
}

@end
