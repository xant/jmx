//
//  JMXEventListener.h
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@interface JMXEventListener : NSObject <JMXV8>
{
#ifdef __JMXV8__
    v8::Persistent<v8::Function> function;
#endif
}

#ifdef __JMXV8__
@property (nonatomic, assign) v8::Persistent<v8::Function> function;
#endif

@property (retain) NSXMLNode *target;
@property (assign) BOOL capture;

- (void)dispatch;

@end
