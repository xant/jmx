//
//  CanvasPattern.mm
//  JMX
//
//  Created by xant on 1/16/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXCanvasPattern.h"
#import "JMXRect.h"

JMXV8_EXPORT_CLASS(JMXCanvasPattern)

static void drawPatternCallback (void * info, CGContextRef context)
{
    JMXCanvasPattern *pattern = (JMXCanvasPattern *)info;
    CGContextDrawImage(context, NSRectToCGRect(pattern.rect.nsRect), pattern.image);
}

static void releaseInfoCallback (void *info)
{
}

// callbacks table
static const CGPatternCallbacks patternCallbacks = {
    0, drawPatternCallback, releaseInfoCallback
};
@implementation JMXCanvasPattern

@synthesize rect, image;

+ (id)patternWithBounds:(NSRect)bounds xStep:(NSUInteger)xStep yStep:(NSUInteger)yStep tiling:(CGPatternTiling)tilingMode isColored:(BOOL)isColored
{
    JMXCanvasPattern *obj = [self alloc];
    if (obj)
        return [[obj initWithBounds:bounds xStep:xStep yStep:yStep tiling:tilingMode isColored:isColored] retain];
    return obj;
}

- (id)initWithBounds:(NSRect)bounds xStep:(NSUInteger)xStep yStep:(NSUInteger)yStep tiling:(CGPatternTiling)tiling isColored:(BOOL)isColored 
{
    self = [super init];
    if (self) {
        rect = [JMXRect rectWithNSRect:bounds];
        tilingMode = tiling;
        CGAffineTransform transformMatrix = CGAffineTransformIdentity;
        currentPattern = CGPatternCreate((void *)self, NSRectToCGRect(bounds), transformMatrix, xStep, yStep, tiling, isColored, &patternCallbacks);
    }
    return self;
}

- (id)jmxInit
{
    return [self init];
}

- (id)init
{
    self = [super init];
    if (self) {
        rect = nil;
        tilingMode = kCGPatternTilingNoDistortion;
        image = nil;
        currentPattern = nil;
        for (int i = 0; i < 4; i++)
            components[i] = 1.0;
    }
    return self;
}

- (CGPatternRef)patternRef
{
    return currentPattern;
    /*if (currentPattern)
        CGPatternRelease(currentPattern);*/
}

- (id)setFromString:(NSString *)style
{
    // TODO - Implement
    return self;
}

- (CGFloat *)components
{
    return components;
}

#pragma mark V8

using namespace v8;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    //v8::Handle<FunctionTemplate> gradientObjectTemplate = FunctionTemplate::New();
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("CanvasPattern"));
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXCanvasPattern jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXCanvasPatternJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length()) { // linear mode
    }
}
@end
