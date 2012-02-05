//
//  JMXColor.m
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "NSColor+V8.h"
#import "JMXScript.h"

using namespace v8;

@implementation NSColor (JMXColor)

// Based on Foley and van Dam algorithm.
void ConvertHSLToRGB (const CGFloat *hslComponents, CGFloat *rgbComponents) {
    CGFloat hue = hslComponents[0];
    CGFloat saturation = hslComponents[1];
    CGFloat lightness = hslComponents[2];
    
    CGFloat temp1, temp2;
    CGFloat rgb[3];  // "temp3"
    
    if (saturation == 0) {
        // Like totally gray man.
        rgb[0] = rgb[1] = rgb[2] = lightness;
        
    } else {
        if (lightness < 0.5) temp2 = lightness * (1.0 + saturation);
        else                 temp2 = (lightness + saturation) - (lightness * saturation);
        
        temp1 = (lightness * 2.0) - temp2;
        
        // Convert hue to 0..1
        hue /= 360.0;
        if (hue > 1.0)
            hue -= floor(hue);
        // Use the rgb array as workspace for our "temp3"s
        rgb[0] = hue + (1.0 / 3.0);
        rgb[1] = hue;
        rgb[2] = hue - (1.0 / 3.0);
        
        // Magic
        for (int i = 0; i < 3; i++) {
            if (rgb[i] < 0.0)        rgb[i] += 1.0;
            else if (rgb[i] > 1.0)   rgb[i] -= 1.0;
            
            if (6.0 * rgb[i] < 1.0)      rgb[i] = temp1 + ((temp2 - temp1)
                                                           * 6.0 * rgb[i]);
            else if (2.0 * rgb[i] < 1.0) rgb[i] = temp2;
            else if (3.0 * rgb[i] < 2.0) rgb[i] = temp1 + ((temp2 - temp1)
                                                           * ((2.0 / 3.0) - rgb[i]) * 6.0);
            else                         rgb[i] = temp1;
        }
    }
    
    // Clamp to 0..1 and put into the return pile.
    for (int i = 0; i < 3; i++) {
        rgbComponents[i] = MAX (0.0, MIN (1.0, rgb[i]));
    }
    
} // ConvertHSLToRGB

+ (id)colorFromCSSString:(NSString *)cssString
{
    // TODO - handle them all
    if ([cssString isEqualToString:@"white"]  ||
        [cssString isEqualToString:@"black"]  ||
        [cssString isEqualToString:@"red"]    ||
        [cssString isEqualToString:@"green"]  ||
        [cssString isEqualToString:@"blue"]   ||
        [cssString isEqualToString:@"gray"]   ||
        [cssString isEqualToString:@"yellow"] ||
        [cssString isEqualToString:@"purple"] ||
        [cssString isEqualToString:@"brown"])
    {
        NSString *selectorString = [NSString stringWithFormat:@"%@Color", cssString];

        return [[NSColor class] performSelector:NSSelectorFromString(selectorString)];
    }
    
    /* TODO - Implement */
    // XXX - requires OSX 10.7
    CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0;
    NSString *colorStringRegExp = @"(#[0-9a-f]+|"
                                  @"rgba\\(\\s*\\d+\\%?\\s*,\\s*\\d+\\%?\\s*,\\s*\\d+\\%?\\s*\\,\\s*[0-9\\.]+\\s*\\)|"
                                  @"hsl\\(\\s*[0-9\\.]+\\%?\\s*,\\s*[0-9\\.]+\\%?\\s*,\\s*[0-9\\.]+\\%?\\s*\\))";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:colorStringRegExp
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    NSUInteger numberOfMatches = [regex numberOfMatchesInString:cssString
                                                        options:0
                                                          range:NSMakeRange(0, [cssString length])];
    
    if (numberOfMatches) {
        NSArray *matches = [regex matchesInString:cssString
                                          options:0
                                            range:NSMakeRange(0, [cssString length])];
        for (NSTextCheckingResult *match in matches) {
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
                    NSString *pattern = @"rgba\\(\\s*(\\d+\\%?)\\s*,\\s*(\\d+\\%?)\\s*,\\s*(\\d+\\%?)\\s*,\\s*([0-9\\.]+)\\s*\\)";
                    NSRegularExpression *subRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                             options:NSRegularExpressionCaseInsensitive
                                                                                               error:&error];
                    
                    
                    NSUInteger numberOfMatches = [subRegex numberOfMatchesInString:substringForFirstMatch
                                                                        options:0
                                                                          range:NSMakeRange(0, [substringForFirstMatch length])];
                    if (numberOfMatches) {
                        NSArray *matches = [subRegex matchesInString:substringForFirstMatch
                                                          options:0
                                                            range:NSMakeRange(0, [substringForFirstMatch length])];
                        NSTextCheckingResult *match = [matches objectAtIndex:0];
                        //NSRange rgbRange = [match range];
                        NSRange redStringRange = [match rangeAtIndex:1];
                        NSString *redString = [substringForFirstMatch substringWithRange:redStringRange];
                        NSRange greenStringRange = [match rangeAtIndex:2];
                        NSString *greenString = [substringForFirstMatch substringWithRange:greenStringRange];
                        NSRange blueStringRange = [match rangeAtIndex:3];
                        NSString *blueString = [substringForFirstMatch substringWithRange:blueStringRange];
                        NSRange alphaStringRange = [match rangeAtIndex:4];
                        NSString *alphaString = [substringForFirstMatch substringWithRange:alphaStringRange];
                        // TODO - handle %
                        if (redString)
                            r = (CGFloat )[redString intValue]/255;
                        if (greenString)
                            g = (CGFloat)[greenString intValue]/255;
                        if (blueString)
                            b = (CGFloat)[blueString intValue]/255;
                        if (alphaString)
                            a = (CGFloat)[alphaString floatValue];
                    }
                    
                } else if ([substringForFirstMatch characterAtIndex:0] == 'h') {
                    NSString *pattern = @"hsl\\(\\s*([0-9\\.]+\\%?)\\s*,\\s*([0-9\\.]+\\%?)\\s*,\\s*([0-9\\.]+\\%?)\\s*\\)";
                    NSRegularExpression *subRegex = [NSRegularExpression regularExpressionWithPattern:pattern
                                                                                              options:NSRegularExpressionCaseInsensitive
                                                                                                error:&error];
                    
                    
                    NSUInteger numberOfMatches = [subRegex numberOfMatchesInString:substringForFirstMatch
                                                                           options:0
                                                                             range:NSMakeRange(0, [substringForFirstMatch length])];
                    if (numberOfMatches) {
                        NSArray *matches = [subRegex matchesInString:substringForFirstMatch
                                                             options:0
                                                               range:NSMakeRange(0, [substringForFirstMatch length])];
                        NSTextCheckingResult *match = [matches objectAtIndex:0];
                        //NSRange rgbRange = [match range];
                        NSRange redStringRange = [match rangeAtIndex:1];
                        NSString *redString = [substringForFirstMatch substringWithRange:redStringRange];
                        NSRange greenStringRange = [match rangeAtIndex:2];
                        NSString *greenString = [substringForFirstMatch substringWithRange:greenStringRange];
                        NSRange blueStringRange = [match rangeAtIndex:3];
                        NSString *blueString = [substringForFirstMatch substringWithRange:blueStringRange];
                        // TODO - handle %
                        if (redString)
                            r = (CGFloat )[redString floatValue];
                        if (greenString)
                            if ([greenString rangeOfString:@"%"].location != NSNotFound) {
                                g = [greenString floatValue]/100.0;
                            } else {
                                g = (CGFloat)[greenString floatValue];
                            }
                        if (blueString)
                            b = (CGFloat)[blueString floatValue];

                        CGFloat rgb[3];
                        CGFloat hsl[3] = { r, g, b };
                        ConvertHSLToRGB(hsl, rgb);
                        r = rgb[0];
                        g = rgb[1];
                        b = rgb[2];
                        a = 1.0;
                    }
                    
                }
            }
        }
    }
    return [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
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
    v8::Handle<FunctionTemplate> objectTemplate = [NSColor jsObjectTemplate];
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
    NSColor *obj = static_cast<NSColor *>(parameter);
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
    v8::Persistent<FunctionTemplate> objectTemplate = [NSColor jsObjectTemplate];
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
    NSColor *color = [[NSColor colorWithDeviceRed:r green:g blue:b alpha:a] retain];
    jsInstance.MakeWeak(color, JMXColorJSDestructor);
    jsInstance->SetPointerInInternalField(0, color);
    [pool drain];
    return handleScope.Close(jsInstance);
}
