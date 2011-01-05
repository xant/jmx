//
//  NSXMLNode+V8.h
//  JMX
//
//  Created by xant on 1/4/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXV8.h"

@interface NSXMLNode (JMXV8) <JMXV8>
#ifdef __JMXV8__
+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate;
+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor;
#endif
@end
