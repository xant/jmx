//
//  JMXCDATA.h
//  JMX
//
//  Created by xant on 1/5/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSXMLNode+V8.h"

@interface JMXCDATA : NSXMLNode {
    NSData *data;
}

@property (retain, readwrite) NSData *data;

#ifdef __JMXV8__
v8::Handle<v8::Value> JMXCDATAJSConstructor(const v8::Arguments& args);
#endif

@end
