//
//  JMXScriptEntity.mm
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXScriptEntity.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXScriptEntity

@synthesize code;

+ (void)initialize
{
    // note that we are called also when subclasses are initialized
    // and we don't want to register global functions multiple times
    if (self == [JMXScriptEntity class]) {
        
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        active = NO;
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

static Persistent<FunctionTemplate> classTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXScriptEntity ClassTemplate created");
    classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);
    classTemplate->SetClassName(String::New("ThreadedEntity"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    return classTemplate;
}

@end
