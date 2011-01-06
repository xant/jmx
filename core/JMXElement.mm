//
//  JMXElement.mm
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXElement.h"

JMXV8_EXPORT_NODE_CLASS(JMXElement);

@implementation JMXElement

- (id)jmxInit
{
    self = [self initWithKind:NSXMLElementKind];
    if (self) {
        self = [super initWithName:@"JMXElement" URI:@"http://jmxapp.org"];
    }
    return self;
}

#pragma mark V8

using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    return [super jsObjectTemplate];
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    return [super jsRegisterClassMethods:constructor];
}

@end
