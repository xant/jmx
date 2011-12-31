//
//  JMXColor.m
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXColor.h"
#import "JMXScript.h"

using namespace v8;

@implementation JMXColor

+ (id)colorFromCSSString:(NSString *)cssString
{
    /* TODO - Implement */
    // XXX - requires OSX 10.7
    CGFloat r = 0.0, g = 0.0, b = 0.0;
    NSString *colorStringRegExp = @"(#[0-9a-f]+|rgb\\(\\s*\\d+\\%?\\s*,\\s*\\d+\\%?\\s*,\\s*\\d+\\%?\\s*\\))";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:colorStringRegExp
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:cssString
                                                        options:0
                                                          range:NSMakeRange(0, [cssString length])];
    
    if (numberOfMatches) {
        NSRange rangeOfFirstMatch = [regex rangeOfFirstMatchInString:cssString options:0 range:NSMakeRange(0, [cssString length])];
        NSArray *matches = [regex matchesInString:cssString
                                          options:0
                                            range:NSMakeRange(0, [cssString length])];
        for (NSTextCheckingResult *match in matches) {
            NSRange matchRange = [match range];
            NSRange rangeOfFirstCapture = [match rangeAtIndex:1];
            if (rangeOfFirstCapture.location + rangeOfFirstCapture.length <= [cssString length]) {
                NSString *substringForFirstMatch = [cssString substringWithRange:rangeOfFirstCapture];
                if ([substringForFirstMatch characterAtIndex:0] == '#') {
                    if (rangeOfFirstCapture.location + rangeOfFirstCapture.length <= [cssString length]) {
                        NSString *substringForFirstMatch = [cssString substringWithRange:rangeOfFirstCapture];
                        if ([substringForFirstMatch length] == 3) {
                            NSMutableString *fullColorString = [NSMutableString stringWithCapacity:6];
                            for (int i = 1; i < [substringForFirstMatch length]; i++) {
                                unichar hexchar = [substringForFirstMatch characterAtIndex:i];
                                NSString *component = [NSString stringWithFormat:@"%c%c", hexchar, hexchar];
                                [fullColorString appendString:component];
                            }
                            substringForFirstMatch = fullColorString;
                        }
                        if ([substringForFirstMatch length] == 6) {
                            NSRange range = { 1, 2 };
                            for (int i = 0; i < 6; i+=2) {
                                NSString *hex = [substringForFirstMatch substringWithRange:range];
                                range.location += 2;
                                int numericalValue = 0;
                                if (sscanf([hex UTF8String], "%02x", &numericalValue) == 0) {
                                    switch (i) {
                                        case 0:
                                            r = numericalValue/255;
                                            break;
                                        case 1:
                                            g = numericalValue/255;
                                            break;
                                        case 2:
                                            b = numericalValue/255;
                                            break;
                                        default:
                                            // TODO - Error Messages
                                            break;
                                    }
                                }
                            }
                        }
                    }
                } else if ([substringForFirstMatch characterAtIndex:0] == 'r') {
                    NSString *pattern = @"rgb\\(\\s*(\\d+\\%?)\\s*,\\s*(\\d+\\%?)\\s*,\\s*(\\d+\\%?)\\s*\\)";
                    NSRegularExpression *subRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                             options:NSRegularExpressionCaseInsensitive
                                                                                               error:&error];
                    NSUInteger numberOfMatches = [subRegex numberOfMatchesInString:substringForFirstMatch
                                                                        options:0
                                                                          range:NSMakeRange(0, [cssString length])];
                    if (numberOfMatches) {
                        NSRange rgbRange = [match range];
                        NSRange redStringRange = [match rangeAtIndex:1];
                        NSString *redString = [substringForFirstMatch substringWithRange:redStringRange];
                        NSRange greenStringRange = [match rangeAtIndex:2];
                        NSString *greenString = [substringForFirstMatch substringWithRange:greenStringRange];
                        NSRange blueStringRange = [match rangeAtIndex:3];
                        NSString *blueString = [substringForFirstMatch substringWithRange:blueStringRange];
                        // TODO - handle %
                        if (redString)
                            r = [redString intValue]/255;
                        if (greenString)
                            g = [greenString intValue]/255;
                        if (blueString)
                            b = [blueString intValue]/255;
                    }
                    
                }
            }
        }
    }
    return [NSColor colorWithDeviceRed:r green:g blue:b alpha:1];
}

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    //v8::Handle<FunctionTemplate> objectTemplate = FunctionTemplate::New();
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Color"));
    //v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();

    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("redComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("blueComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("greenComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("whiteComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("blackComponent"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("alphaComponent"), GetDoubleProperty);
    return objectTemplate;
}

- (void)dealloc
{
    [super dealloc];
}

- (CGFloat)r
{
    return [self redComponent];
}

- (CGFloat)g
{
    return [self greenComponent];
}

- (CGFloat)b
{
    return [self blueComponent];
}

- (CGFloat)a
{
    return [self alphaComponent];
}

#pragma mark -
#pragma mark V8

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXColor jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
}

- (id)setFromString:(NSString *)style
{
    // TODO - Implement
    return nil;
}

@end

static void JMXColorJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXColor *obj = static_cast<JMXColor *>(parameter);
    //NSLog(@"V8 WeakCallback (Color) called ");
    [obj release];
    //Persistent<Object> instance = v8::Persistent<Object>::Cast(object);
    //instance.ClearWeak();
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
    //object.Clear();
}

v8::Handle<v8::Value> JMXColorJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    //v8::Locker locker;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXColor jsObjectTemplate];
    CGFloat r = 0.0;
    CGFloat g = 0.0;
    CGFloat b = 0.0;
    CGFloat a = 1.0; // make it visible by default
    if (args.Length() >= 3) {
        r = args[0]->NumberValue();
        g = args[1]->NumberValue();
        b = args[2]->NumberValue();
        // if alpha has been provided, override the default value
        if (args.Length() >= 4)
            a = args[3]->NumberValue();
    }
    Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXColor *color = [[JMXColor colorWithDeviceRed:r green:g blue:b alpha:a] retain];
    jsInstance.MakeWeak(color, JMXColorJSDestructor);
    jsInstance->SetPointerInInternalField(0, color);
    [pool drain];
    return handleScope.Close(jsInstance);
}
