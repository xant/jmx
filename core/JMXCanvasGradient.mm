//
//  JMXCanvasGradient.mm
//  JMX
//
//  Created by xant on 1/16/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXCanvasGradient.h"
#import "NSColor+V8.h"
#import "JMXPoint.h"

#pragma mark JMXCanvasGradient

JMXV8_EXPORT_CLASS(JMXCanvasGradient)

@implementation JMXCanvasGradient

@synthesize mode;

+ (id)linearGradientFrom:(JMXPoint *)from to:(JMXPoint *)to
{
    JMXCanvasGradient *obj = [self alloc];
    if (obj) {
        return [[obj initLinearFrom:from to:to] autorelease];
    }
    return obj;
}

+ (id)radialGradientFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2
{
    JMXCanvasGradient *obj = [self alloc];
    if (obj) {
        return [[obj initRadialFrom:from radius:r1 to:to radius:r2] autorelease];
    }
    return obj;
}

- (id)initLinearFrom:(JMXPoint *)from to:(JMXPoint *)to
{
    self = [super init];
    if (self) {
        srcPoint = [from copy];
        dstPoint = [to copy];
        mode = kJMXCanvasGradientLinear;
    }
    return self;
}

- (id)initRadialFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2
{
    self = [super init];
    if (self) {
        srcPoint = [from copy];
        srcRadius = r1;
        dstPoint = [to copy];
        dstRadius = r2;
        mode = kJMXCanvasGradientRadial;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        colors = [[NSMutableArray alloc] init];
        locations = [[NSMutableArray alloc] init];
        currentGradient = nil;
        srcPoint = nil;
        srcRadius = 0;
        dstPoint = nil;
        dstRadius = 0;
        mode = kJMXCanvasGradientNone;
    }
    return self;
}

- (id)jmxInit
{
    return [self init];
}

- (void)addColor:(NSColor *)color stop:(NSUInteger)offset
{
    [colors addObject:color];
    [locations addObject:[NSNumber numberWithUnsignedInt:offset]];
}

- (CGGradientRef)gradientRef
{
    if (currentGradient)
        CGGradientRelease(currentGradient);
    NSUInteger count = [locations count];
    CGFloat loc[count];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    for (int i = 0; i < count; i++) {
        loc[i] = [[locations objectAtIndex:i] floatValue];
    }
    currentGradient = CGGradientCreateWithColors(colorSpace, (CFArrayRef)colors, loc);
    CGColorSpaceRelease(colorSpace);
    return currentGradient;
}

- (id)setFromString:(NSString *)style
{
    /* TODO - Implement */
    return nil;
}

#pragma mark V8 (JMXCanvasGradient)

static v8::Handle<Value> AddColorStop(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXCanvasGradient *gradient = (JMXCanvasGradient *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1) {
        v8::String::Utf8Value colorString(args[0]);
        double offset = args[1]->NumberValue();
        NSColor *color = [NSColor colorFromCSSString:[NSString stringWithUTF8String:*colorString]];
        if (color) {
            [gradient addColor:color stop:offset];
        }
    }
    return handleScope.Close(Undefined());
}


+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    //v8::Handle<FunctionTemplate> gradientObjectTemplate = FunctionTemplate::New();
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("CanvasGradient"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("addColorStop", FunctionTemplate::New(AddColorStop));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXCanvasGradient jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXCanvasGradientJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length() == 4) { // linear mode
        srcPoint = [JMXPoint pointWithNSPoint:NSMakePoint((*args)[0]->NumberValue(), (*args)[1]->NumberValue())];
        srcRadius = 0;
        dstPoint = [JMXPoint pointWithNSPoint:NSMakePoint((*args)[2]->NumberValue(), (*args)[3]->NumberValue())];
        dstRadius = 0;
        mode = kJMXCanvasGradientLinear;
    } else if (args->Length() == 6) { // radial mode
        srcPoint = [JMXPoint pointWithNSPoint:NSMakePoint((*args)[0]->NumberValue(), (*args)[1]->NumberValue())];
        srcRadius = (*args)[2]->NumberValue();
        dstPoint = [JMXPoint pointWithNSPoint:NSMakePoint((*args)[3]->NumberValue(), (*args)[4]->NumberValue())];
        dstRadius = (*args)[5]->NumberValue();
        mode = kJMXCanvasGradientLinear;
    }
}

@end
