//
//  JMXCanvasElement.mm
//  JMX
//
//  Created by xant on 1/15/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXCanvasElement.h"
#import "JMXScript.h"
#import "JMXV8PropertyAccessors.h"
#import "JMXSize.h"
#import "JMXDrawPath.h"

JMXV8_EXPORT_NODE_CLASS(JMXCanvasElement);

@implementation JMXCanvasElement

@synthesize width, height, drawPath;

- (id)initWithName:(NSString *)name
{
    return [self init];
}

- (id)initWithFrameSize:(JMXSize *)frameSize
{
    self = [super init];
    if (self) {
        self.name = @"canvas";
        self.width = frameSize.width; // HC
        self.height = frameSize.height; // HC
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:[JMXSize sizeWithNSSize:NSMakeSize(self.width, self.height)]];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.name = @"canvas";
        self.width = 640; // HC
        self.height = 480; // HC
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:[JMXSize sizeWithNSSize:NSMakeSize(self.width, self.height)]];
    }
    return self;
}

#pragma mark V8

using namespace v8;

static v8::Handle<Value> GetContext(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCanvasElement *element = (JMXCanvasElement *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    
    return [element.drawPath jsObj];
}

static v8::Handle<Value> ToDataURL(const Arguments& args)
{
    // TODO - Implement
    return v8::Undefined();
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Canvas"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("getContext", FunctionTemplate::New(GetContext));
    classProto->Set("toDataURL", FunctionTemplate::New(ToDataURL));

    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetDoubleProperty, SetDoubleProperty);
    
    NSLog(@"JMXElement objectTemplate created");
    return objectTemplate;
}

@end
