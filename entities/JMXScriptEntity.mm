//
//  JMXScriptEntity.mm
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__ 1
#import "JMXScriptEntity.h"
#import "JMXScript.h"
#import "JMXProxyPin.h"
#import "JMXGraphFragment.h"
#import "JMXScriptInputPin.h"
#import "JMXScriptOutputPin.h"
#import "JMXImageData.h"
#import "NSColor+V8.h"
#import "JMXScriptPinWrapper.h"
#import "JMXByteArray.h"
#import "NSDictionary+V8.h"

using namespace v8;

@implementation JMXScriptEntity

@synthesize code, arguments, jsContext, executionThread;

+ (void)initialize
{
    // note that we are called also when subclasses are initialized
    // and we don't want to register global functions multiple times
    if (self == [JMXScriptEntity class]) {
        
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        self.label = @"ScriptEntity";
        pinWrappers = [[NSMutableSet alloc] initWithCapacity:25];
        codeOutputPin = [self registerOutputPin:@"runningCode" withType:kJMXCodePin andSelector:@"code"];

    }
    return self;
}

- (id)retain
{
    return [super retain];
}
- (void)dealloc
{
    [self resetContext];
    [executionThread release];
    [pinWrappers release];
    [super dealloc];
}

- (JMXScriptPinWrapper *)wrapPin:(JMXPin *)pin withFunction:(v8::Persistent<v8::Function>)function
{
    JMXScriptPinWrapper *wrapper = [JMXScriptPinWrapper pinWrapperWithName:@"jsFunction"
                                                            function:function
                                                              scriptEntity:self];
    [wrapper connectToPin:pin];
    [pinWrappers addObject:wrapper];
    return wrapper; // XXX
}

- (void)resetContext
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    for (JMXScriptPinWrapper *wrapper in pinWrappers)
        [wrapper disconnect];
    [pinWrappers removeAllObjects];

    // we want to release our context.
    // first thing ... let's detach all entities we have created
    for (NSXMLNode *node in [self children]) {
        if ([node isKindOfClass:[JMXGraphFragment class]]) {
            for (JMXEntity *entity in [node children]) {
                [entity detach];
            }
            [node detach];
        } 
    }
    if (jsContext) {
        [jsContext stop];
        [jsContext release];
        jsContext = nil;
    }
    NSArray *elements = [self elementsForName:@"Entities"];
    JMXElement *holder = [elements count] ? [elements objectAtIndex:0] : nil;
    if (holder) {
        for (NSXMLNode *node in [holder children])
            [node detach];
        [holder detach];
    }
    [pool drain];
}

- (BOOL)execFunction:(v8::Handle<v8::Function>)function
{
    if (jsContext)
        return [jsContext execFunction:function];
    return NO;
}

- (BOOL)exec:(NSString *)someCode
{
    if (!someCode)
        someCode = self.code;
    if (!jsContext) {
        jsContext = [[JMXScript alloc] init];
        [jsContext startWithEntity:self];
    }
    [executionThread release];
    executionThread = [[NSThread currentThread] retain];
    return [jsContext runScript:someCode withArgs:self.arguments];
}

- (BOOL)exec
{
    return [self exec:nil];
}

- (void)hookEntity:(JMXEntity *)entity
{
    NSArray *elements = [self elementsForName:@"Entities"];
    JMXElement *holder = [elements count] ? [elements objectAtIndex:0] : nil;
    if (!holder) {
        holder = [[JMXGraphFragment alloc] initWithName:@"Entities"];
        [self addChild:holder];
    }
    [holder addChild:entity];
}

- (JMXScriptInputPin *)registerJSInputPinWithLabel:(NSString *)aLabel
                                        type:(JMXPinType)type
                                    function:(v8::Persistent<v8::Function>)function
{
    //JMXInputPin *pin = [self registerInputPin:aLabel withType:type];
    JMXScriptInputPin *pin = [[[JMXScriptInputPin alloc] initWithLabel:aLabel andType:type ownedBy:self withSignal:nil] autorelease];
    pin.function = function;
    [self registerInputPin:pin];
    return pin;
}

- (JMXScriptOutputPin *)registerJSOutputPinWithLabel:(NSString *)aLabel
                                          type:(JMXPinType)type
                                      function:(v8::Persistent<v8::Function>)function
{
    JMXScriptOutputPin *pin = [[[JMXScriptOutputPin alloc] initWithLabel:aLabel andType:type ownedBy:self withSignal:nil] autorelease];
    pin.function = function;
    [self registerOutputPin:pin];
    return pin;
}

- (NSString *)code
{
    @synchronized(jsContext) {
        return [[code copy] autorelease];
    }
}

- (void)setCode:(NSString *)someCode
{
    @synchronized(jsContext) {
        if (code == someCode)
            return;
        [code release];
        code = [someCode copy];
        codeOutputPin.data = code;
    }
}

#pragma mark -
#pragma JMXPinOwner
- (id)provideDataToPin:(JMXOutputPin *)aPin
{
    if ([aPin isKindOfClass:[JMXScriptOutputPin class]]) {
        JMXScriptOutputPin *pin = (JMXScriptOutputPin *)aPin;
        if (pin.function.IsEmpty() || pin.function->IsNull() || pin.function->IsUndefined())
            return nil;
        Locker locker;
        HandleScope handleScope;
        Handle<Value> args[1];
        v8::Context::Scope context_scope(jsContext.ctx);
        args[0] = [pin jsObj];
        Handle<Value> ret = [jsContext execFunction:pin.function withArguments:args count:1];
        if (ret.IsEmpty()) {
            return nil;
        } else if (ret->IsNumber()) {
            return [NSNumber numberWithDouble:ret->ToNumber()->NumberValue()];
        } else if (ret->IsString()) {
            String::Utf8Value str(ret->ToString());
            return [NSString stringWithUTF8String:*str];
        } else if (ret->IsObject()) {
            return (id)ret->ToObject()->GetPointerFromInternalField(0);
        }
    } else {
        return [super provideDataToPin:aPin];
    }
    return nil;
}

- (void)receiveData:(id)data fromPin:(JMXInputPin *)aPin
{
    if ([aPin isKindOfClass:[JMXScriptInputPin class]]) {
        Locker locker;
        HandleScope handleScope;
        Handle<Value> args[1];
        args[0] = Undefined();
        v8::Context::Scope context_scope(jsContext.ctx);
        JMXScriptInputPin *pin = (JMXScriptInputPin *)aPin;
        if (pin.function.IsEmpty() || pin.function->IsNull() || pin.function->IsUndefined())
            return;
        switch (pin.type) {
            case kJMXStringPin:
            case kJMXTextPin:
            case kJMXCodePin:
                args[0] = v8::String::New([(NSString *)data UTF8String]);
                break;
            case kJMXNumberPin:
                args[0] = v8::Number::New([(NSNumber *)data doubleValue]);
                break;
            case kJMXImagePin:
                args[0] = [[JMXImageData imageDataWithImage:(CIImage *)data rect:[(CIImage *)data extent]] jsObj];
                break;
            case kJMXColorPin:
                args[0] = [(NSColor *)data jsObj];
                break;
            case kJMXSizePin:
                args[0] = [(JMXSize *)data jsObj];
                break;
            case kJMXByteArrayPin:
                args[0] = [(JMXByteArray *)data jsObj];
                break;
            case kJMXDictionaryPin:
                args[0] = [(NSDictionary *)data jsObj];
                break;
            case kJMXPointPin:
                args[0] = [(JMXPoint *)data jsObj];
                break;
            default:
                // TODO - Error Message
                break;
        }
        [jsContext execFunction:pin.function withArguments:args count:1];
    } else {
        [super receiveData:data fromPin:aPin];
    }
    // XXX - base implementation doesn't do anything
}


// WEAK ... because referenced by the script context itself ... would create a circular reference if retained
// and would end up in leaking memory
- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

static Persistent<FunctionTemplate> objectTemplate;

static v8::Handle<Value>Exec(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret;
    HandleScope handleScope;
    JMXScriptEntity *entity = (JMXScriptEntity *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (args[0]->IsFunction()) {
        ret = [entity execFunction:Local<Function>::New(Handle<Function>::Cast(args[0]))];
    } else if (args[0]->IsString()) {
        String::Utf8Value str(args[0]->ToString());
        [entity exec:[NSString stringWithUTF8String:*str]];
    } else {
        NSLog(@"ScriptEntity::exec(): argument is neither a string nor a function");
    }
    [pool release];
    return handleScope.Close(v8::Boolean::New(ret ? 1 : 0));
}

static v8::Handle<Value>GetEntities(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXScriptEntity *entity = (JMXScriptEntity *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *entities = [entity elementsForName:@"Entities"];
    v8::Handle<Array> list = Array::New(entities.count);
    if (entities.count) {
        JMXElement *holder = [entities objectAtIndex:0];
        int cnt = 0;
        for (NSXMLNode *node in [holder children]) {
            if ([node isKindOfClass:[JMXEntity class]]) {
                list->Set(cnt++, [(JMXEntity *)node jsObj]);
            }
        }
    }
    [pool release];
    return handleScope.Close(list);
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    NSDebug(@"JMXScriptEntity objectTemplate created");
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("ScriptEntity"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    classProto->Set("exec", FunctionTemplate::New(Exec));
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetAccessor(String::NewSymbol("frequency"), GetNumberProperty, SetNumberProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("entities"), GetEntities);
    instanceTemplate->SetAccessor(String::NewSymbol("code"), GetStringProperty, SetStringProperty);
    
    instanceTemplate->SetInternalFieldCount(1);
    return objectTemplate;
}

@end
