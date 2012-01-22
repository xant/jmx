//
//  JMXScriptTimer.m
//  JMX
//
//  Created by Andrea Guzzo on 1/22/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXScriptTimer.h"

using namespace v8;

@implementation JMXScriptTimer

@synthesize function, timer, repeats, statements;//, block;

+ (id)scriptTimerWithFireDate:(NSDate *)date
                     interval:(NSTimeInterval)interval
                       target:(id)target
                     selector:(SEL)selector
                      repeats:(BOOL)repeats
{
    return [[[self alloc] initWithFireDate:date
                                  interval:interval
                                    target:target
                                  selector:selector
                                   repeats:repeats] autorelease];
}

- (id)initWithFireDate:(NSDate *)date
              interval:(NSTimeInterval)interval
                target:(id)target
              selector:(SEL)selector
               repeats:(BOOL)shouldRepeat
{
    self = [super init];
    if (self) {
        timer = [[NSTimer alloc] initWithFireDate:[NSDate dateWithTimeIntervalSinceNow:interval]
                                     interval:interval
                                       target:target
                                     selector:selector
                                     userInfo:self
                                      repeats:shouldRepeat];
        repeats = shouldRepeat;
    }
    return self;

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
    
    objectTemplate->SetClassName(String::New("Timer"));
    //v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    //instanceTemplate->SetAccessor(String::NewSymbol("redComponent"), GetDoubleProperty);
    
    return objectTemplate;
}

- (void)dealloc
{
    if (!function.IsEmpty())
        function.Dispose();
    [timer release];
    [statements release];
    [super dealloc];
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [JMXScriptTimer jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

@end