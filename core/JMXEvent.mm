//
//  JMXEvent.m
//  JMX
//
//  Created by Andrea Guzzo on 1/29/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXEvent.h"
#import "JMXScript.h"

JMXV8_EXPORT_CLASS(JMXEvent);

using namespace v8;

@implementation JMXEvent

@synthesize type, target, listener, relatedTarget;

+ (id)eventWithType:(NSString *)type
             target:(NSXMLNode *)target
           listener:(JMXEventListener *)listener
            capture:(BOOL)capture
{
    return [[[JMXEvent alloc] initWithType:type
                                    target:target
                                  listener:listener
                                   capture:capture] autorelease];
}

- (id)initWithType:(NSString *)aType
            target:(NSXMLNode *)aTarget
          listener:(JMXEventListener *)aListener
           capture:(BOOL)b
{
    self = [super init];
    if (self) {
        type = [aType copy];
        listener = [aListener retain];
        capture = b;
        target = [aTarget retain];
    }
    return self;
}

- (void)dealloc
{
    [type release];
    [listener release];
    [target release];
    [timeStamp release];
    [super dealloc];
}

- (BOOL)isEqual:(JMXEvent *)anObject
{
    return ([type isEqual:anObject.type] && target == target && listener == listener);
}



#pragma mark V8

- (void)_initInternal:(v8::Arguments *)args
{
    if (args->Length() >= 1) {
        v8::Handle<Value> arg = (*args)[0];
        v8::String::Utf8Value evtType(arg);
        self.type = [NSString stringWithFormat:@"%s", *evtType];
    }
}

- (void)jsInit:(NSValue *)argsValue
{
    v8::Locker lock;
    HandleScope handleScope;
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    [self _initInternal:args];
}

static v8::Handle<Value>InitEvent(const Arguments& args)
{
    v8::Locker lock;
    HandleScope handleScope;
    if (args.Length() >= 1) {
        JMXEvent *event = (JMXEvent *)args.Holder()->GetPointerFromInternalField(0);
        [event _initInternal:(v8::Arguments *)&args];
    }
    return handleScope.Close(Undefined());
}

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    v8::Locker lock;
    HandleScope handleScope;
    
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    
    objectTemplate->SetClassName(String::New("Event"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    classProto->Set("initEvent", FunctionTemplate::New(InitEvent));

    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("type"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("target"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("eventPhase"), GetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("bubbles"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("eventPhase"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("cancelable"), GetBoolProperty);
    // TODO - date properties
    
    return objectTemplate;
}

//static void JMXEventJSDestructor(Persistent<Value> object, void *parameter)
//{
//    HandleScope handle_scope;
//    Locker lock;
//    JMXEvent *obj = static_cast<JMXEvent *>(parameter);
//    //NSLog(@"V8 WeakCallback (Rect) called %@", obj);
//    [obj release];
//    if (!object.IsEmpty()) {
//        object.ClearWeak();
//        object.Dispose();
//        object.Clear();
//    }
//}

- (Handle<Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    jsInstance.MakeWeak([self retain], JMXEventJSDestructor);
    return handle_scope.Close(jsInstance);
}

@end
