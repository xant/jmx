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

@synthesize drawPath;

- (id)initWithName:(NSString *)name
{
    return [self initWithName:@"canvas"];
}

- (id)initWithFrameSize:(JMXSize *)frameSize
{
    self = [super initWithName:@"canvas"];
    if (self) {
        width = frameSize.width;
        height = frameSize.height;
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:[JMXSize sizeWithNSSize:NSMakeSize(width, height)]];
    }
    return self;
}

- (id)init
{
    self = [super initWithName:@"canvas"];
    if (self) {
        self.width = 640; // HC
        self.height = 480; // HC
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:[JMXSize sizeWithNSSize:NSMakeSize(self.width, self.height)]];
    }
    return self;
}

- (double)height
{
    return height;
}

- (void)setWidth:(double)aWidth
{
    if (aWidth != width) {
        width = aWidth;
        [drawPath setFrameSize:[JMXSize sizeWithNSSize:NSSizeFromCGSize(CGSizeMake(aWidth, height))]];
    }
}

- (double)width
{
    return width;
}

- (void)setHeight:(double)aHeight
{
    if (aHeight != height) {
        height = aHeight;
        [drawPath setFrameSize:[JMXSize sizeWithNSSize:NSSizeFromCGSize(CGSizeMake(width, aHeight))]];
    }
}

- (void)dealloc
{
    [drawPath release];
    [super dealloc];
}

#pragma mark V8

using namespace v8;

static v8::Handle<Value> GetContext(const Arguments& args)
{
    //v8::Locker lock;
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    
    if (strcasecmp(*value, "2d") == 0) { 
        HandleScope handleScope;
        JMXCanvasElement *element = (JMXCanvasElement *)args.Holder()->GetPointerFromInternalField(0);

        
        return handleScope.Close([element.drawPath jsObj]);
    } 
    return Undefined();
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
    objectTemplate->SetClassName(String::New("HTMLCanvasElement"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("getContext", FunctionTemplate::New(GetContext));
    classProto->Set("toDataURL", FunctionTemplate::New(ToDataURL));

    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetDoubleProperty, SetDoubleProperty);
    
    NSDebug(@"JMXCanvas objectTemplate created");
    return objectTemplate;
}

@end
