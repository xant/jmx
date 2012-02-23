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
#include <regex.h>

#define kNSColorV8MaxCache 4096

static char colorStringRegExp[] = "(#[0-9a-f]+|"
                                  "rgba\\([[:space:]]*[0-9]+\\%?[[:space:]]*,[[:space:]]*[0-9]+\\%?[[:space:]]*,[[:space:]]*[0-9]+\\%?[[:space:]]*,[[:space:]]*[0-9\\.]+[[:space:]]*\\)|"
                                  "rgb\\([[:space:]]*[0-9]+\\%?[[:space:]]*,[[:space:]]*[0-9]+\\%?[[:space:]]*,[[:space:]]*[0-9]+\\%?[[:space:]]*\\)|"
                                  "hsl\\([[:space:]]*[0-9\\.]+\\%?[[:space:]]*,[[:space:]]*[0-9\\.]+\\%?[[:space:]]*,[[:space:]]*[0-9\\.]+\\%?[[:space:]]*\\))";

static char rgbaRegExp[] =  "(rgba\\([[:space:]]*([0-9]+\\%?)[[:space:]]*,[[:space:]]*([0-9]+\\%?)[[:space:]]*,[[:space:]]*([0-9]+\\%?)[[:space:]]*,[[:space:]]*([0-9\\.]+)[[:space:]]*\\)|"
"rgb\\([[:space:]]*([0-9]+\\%?)[[:space:]]*,[[:space:]]*([0-9]+\\%?)[[:space:]]*,[[:space:]]*([0-9]+\\%?)[[:space:]]*\\))";

static char hslRegExp[] = "hsl\\([[:space:]]*([0-9\\.]+\\%?)[[:space:]]*,[[:space:]]*([0-9\\.]+\\%?)[[:space:]]*,[[:space:]]*([0-9\\.]+\\%?)[[:space:]]*\\)";

using namespace v8;

static NSMutableDictionary *colorCache = nil;

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
    NSColor *color = nil;
    if (!colorCache) {
        colorCache = [[NSMutableDictionary alloc] initWithCapacity:kNSColorV8MaxCache];
    } else {
        color = [colorCache objectForKey:cssString];
        if (color)
            return color;
    }
    
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

        color = [[NSColor class] performSelector:NSSelectorFromString(selectorString)];
        if (color)
            [colorCache setObject:color forKey:cssString];
        return color;
    }
    
    CGFloat r = 0.0, g = 0.0, b = 0.0, a = 1.0;
    NSError *error = NULL;
    
    
    static regex_t exp;
    static bool mainExpInitialized = false;
    if (!mainExpInitialized) {
        if ((regcomp(&exp, colorStringRegExp, REG_EXTENDED|REG_ICASE) == 0)) {
            mainExpInitialized = true;
        } else {
            
        }
    }
    regmatch_t matches[1] = { { 0, 0 } };
    // normal normal normal 12px/14.399999999999999px "Arial", sans-serif
    if (mainExpInitialized) {
        int code = regexec(&exp, [cssString UTF8String], 1, matches, 0);
        if (code == 0) {
            int length = matches[0].rm_eo-matches[0].rm_so;
            if (length) {
                char *string = (char *)malloc(length + 1);
                strncpy(string, [cssString UTF8String] + matches[0].rm_so, length);
                string[length] = 0;
                if (*string == '#') {
                    NSMutableString *fullColorString = [NSMutableString stringWithUTF8String:string+1];
                    if (length == 4) {
                        fullColorString = [NSMutableString stringWithCapacity:6];
                        for (int i = 1; i < length; i++) {
                            unichar hexchar = string[i];
                            NSString *component = [NSString stringWithFormat:@"%c%c", hexchar, hexchar];
                            [fullColorString appendString:component];
                        }
                        [fullColorString appendString:@"ff"];
                    } else if (length == 7) {
                        [fullColorString appendString:@"ff"];
                    }
                    if (fullColorString && fullColorString.length == 8) {
                        NSRange range = { 0, 2 };
                        for (int i = 0; i < 8; i+=2) {
                            NSString *hex = [fullColorString substringWithRange:range];
                            range.location += 2;
                            CGFloat numericalValue = 0;
                            if (sscanf([hex UTF8String], "%02x", &numericalValue) == 1) {
                                switch (i) {
                                    case 0:
                                        r = numericalValue/255.0;
                                        break;
                                    case 2:
                                        g = numericalValue/255.0;
                                        break;
                                    case 4:
                                        b = numericalValue/255.0;
                                        break;
                                    case 6:
                                        a =  numericalValue/255.0;
                                    default:
                                        // TODO - Error Messages
                                        break;
                                }
                            }
                        }
                    }
                } else if (*string == 'r') {                  
                    static regex_t rgbaexp;
                    static bool rgbaExpInitialized = false;
                    if (!rgbaExpInitialized) {
                        if ((regcomp(&rgbaexp, rgbaRegExp,  REG_EXTENDED|REG_ICASE) == 0)) {
                            rgbaExpInitialized = true;
                        }
                    }
                    regmatch_t submatches[6];
                    memset(submatches, 0, sizeof(submatches));
                    if (rgbaExpInitialized) {
                        int subcode = regexec(&rgbaexp, string, 6, submatches, 0);
                        if (subcode == 0) {
                            for (int i = 2; i < 6; i++) { // NOTE: the first two matches are the whole string
                                if (submatches[i].rm_so && submatches[i].rm_eo) {
                                    int sublength = submatches[i].rm_eo - submatches[i].rm_so;
                                    char *substring = (char *)malloc(sublength + 1);
                                    strncpy(substring, string + submatches[i].rm_so, sublength);
                                    substring[sublength] = 0;
                                    double floatValue = 0;
                                    int integerValue = 0;
                                    BOOL isFloat = strchr(substring, '.') ? YES : NO;
                                    int ret = (isFloat || i == 5) ? sscanf(substring, "%lf", &floatValue) : sscanf(substring, "%d", &integerValue);
                                    if (ret == 1) {
                                        switch (i) {
                                            case 2:
                                                r = (isFloat ? floatValue : integerValue)/255.0;
                                                break;
                                            case 3:
                                                g = (isFloat ? floatValue : integerValue)/255.0;
                                                break;
                                            case 4:
                                                b = (isFloat ? floatValue : integerValue)/255.0;
                                                break;
                                            case 5:
                                                a = floatValue;
                                                if (a > 1)
                                                    a /= 255;
                                                break;
                                            default:
                                                // TODO - Error Messages
                                                break;
                                        }
                                    }
                                    free(substring);
                                }
                            }

                        } else {
                            char error[1024];
                            regerror(subcode, &exp, error, 1024);
                            NSLog(@"Error parsing css color string: %d - %s", subcode, error);
                        }
                    }
                } else if (*string == 'h') {
                    static regex_t hslexp;
                    static bool hslExpInitialized = false;
                    if (!hslExpInitialized) {
                        if ((regcomp(&hslexp, hslRegExp, REG_EXTENDED|REG_ICASE) == 0)) {
                            hslExpInitialized = true;
                        }
                    }
                    regmatch_t submatches[4];
                    memset(submatches, 0, sizeof(submatches));
                    if (hslExpInitialized) {
                        int subcode = regexec(&hslexp, string, 5, submatches, 0);
                        if (subcode == 0) {
                            for (int i = 1; i < 5; i++) { // NOTE: the first two matches are the whole string
                                if (submatches[i].rm_so && submatches[i].rm_eo) {
                                    int sublength = submatches[i].rm_eo - submatches[i].rm_so;
                                    char *substring = (char *)malloc(sublength + 1);
                                    strncpy(substring, string + submatches[i].rm_so, sublength);
                                    substring[sublength] = 0;
                                    CGFloat numericalValue = 0;
                                    // TODO - handle %
                                    if (sscanf(substring, "%lf", &numericalValue) == 1) {
                                        switch (i) {
                                            case 1:
                                                r = numericalValue;
                                                break;
                                            case 2:
                                                g = numericalValue;
                                                break;
                                            case 3:
                                                b = numericalValue;
                                                break;
                                        }
                                    }
                                    free(substring);
                                }
                            }
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
                free(string);
            }
        } else {
            char error[1024];
            regerror(code, &exp, error, 1024);
            NSLog(@"Error parsing css color string: %d - %s", code, error);
        }
        //regfree(&exp);
    }
    
    color = [NSColor colorWithDeviceRed:r green:g blue:b alpha:a];
    if (color) {
        if (colorCache.count >= kNSColorV8MaxCache) {
            [colorCache removeObjectsForKeys:[[colorCache allKeys] objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, colorCache.count/2)]]];
        }
        [colorCache setObject:color forKey:cssString];
    }
    return color;
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

- (CGFloat)w
{
    return [self whiteComponent];
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
    
    // ad shortcuts (just aliases)
    instanceTemplate->SetAccessor(String::NewSymbol("r"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("b"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("g"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("w"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("b"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("a"), GetDoubleProperty);
    return objectTemplate;
}

#pragma mark -
#pragma mark V8

static void JMXColorJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    NSColor *obj = static_cast<NSColor *>(parameter);
    //NSLog(@"V8 WeakCallback (Color) called ");
    [obj release];
    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [NSColor jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXColorJSDestructor);
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
