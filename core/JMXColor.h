//
//  JMXColor.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"


@interface JMXColor : NSColor <JMXV8> {
    
}

#ifdef __JMXV8__
v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args);
#endif
@end
