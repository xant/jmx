//
//  JMXGraph.mm
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXGraph.h"
#import "JMXScript.h"


@implementation JMXGraph

- (id)init
{
    self = [super init];
    if (self) {
        
    }
    return self;
}

#pragma mark V8
using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = [super jsObjectTemplate];
    entityTemplate->SetClassName(String::New("Graph"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    /*
    instanceTemplate->SetAccessor(String::NewSymbol("doctype"), );
    instanceTemplate->SetAccessor(String::NewSymbol("implementation"), );
    instanceTemplate->SetAccessor(String::NewSymbol("documentElement"), );
    instanceTemplate->SetAccessor(String::NewSymbol("xmlEncoding"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("xmlStandalone"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("xmlVersion"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("strictErrorChecking"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("documentURI"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("domConfig"), , );
     */
    return entityTemplate;
}

@end
