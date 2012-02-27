//
//  NSFont+V8.m
//  JMX
//
//  Created by xant on 3/30/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "NSFont+V8.h"
#import "JMXScript.h"
#import "JMXV8PropertyAccessors.h"

//JMXV8_EXPORT_PERSISTENT_CLASS(NSFont);

@implementation NSFont (JMXV8)

#pragma mark -
#pragma mark V8


- (id)jmxInit
{
    return [self init];
}

using namespace v8;

static Persistent<FunctionTemplate> objectTemplate;

+ (Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Font"));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors to font properties.
    instanceTemplate->SetAccessor(String::NewSymbol("size"), GetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty);
    // TODO - handle flags like bold, underlined, whatever
    return objectTemplate;
}

@end

static void NSFontJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    NSFont *obj = static_cast<NSFont *>(parameter);
    //NSLog(@"V8 WeakCallback (Font) called ");
    [obj release];

    if (!object.IsEmpty()) {
        object.ClearWeak();
        object.Dispose();
        object.Clear();
    }
    //object.Clear();
}

v8::Handle<v8::Value> NSFontJSConstructor(const v8::Arguments& args)
{
    HandleScope handleScope;
    NSFont *font = nil;
    //v8::Locker locker;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CGFloat fsize = 12;
    
    if (objectTemplate.IsEmpty()) {
        objectTemplate = [NSFont jsObjectTemplate];
    }
    if (args.Length()) {
        v8::String::Utf8Value fname(args[0]);
        if (font) {
            if (args.Length() > 1) {
                fsize = args[1]->NumberValue();
            }
        }
        font = [[NSFont fontWithName:[NSString stringWithUTF8String:*fname] size:fsize] retain];
    }
    [pool drain];
    if (font) {
        Persistent<Object>jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
        jsInstance.MakeWeak(font, NSFontJSDestructor);
        jsInstance->SetPointerInInternalField(0, font);
        return handleScope.Close(jsInstance);
    }
    return handleScope.Close(Undefined());
}