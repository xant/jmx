//
//  JMXProxyPin.h
//  JMX
//
//  Created by xant on 12/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXPin.h"

@interface JMXProxyPin : NSProxy {
    JMXPin *realObject;
    NSString *overriddenName;
}

- (id)initWithPin:(JMXPin *)pin andName:(NSString *)name;
+ (id)proxyPin:(JMXPin *)pin withName:(NSString *)name;
@end
