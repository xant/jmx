//
//  JMXGraphFragment.m
//  JMX
//
//  Created by Andrea Guzzo on 12/30/11.
//  Copyright (c) 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXGraphFragment.h"

JMXV8_EXPORT_NODE_CLASS(JMXGraphFragment);

using namespace v8;

@implementation JMXGraphFragment

#pragma mark V8

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("DocumentFragment"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    NSDebug(@"JMXGraphFragment objectTemplate created");
    return objectTemplate;
}
@end
