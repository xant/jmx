//
//  JMXScriptPinWrapper.m
//  JMX
//
//  Created by Andrea Guzzo on 2/1/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXScriptPinWrapper.h"
#import "JMXScriptEntity.h"
#import "JMXPin.h"
#import "JMXPinSignal.h"
#import "JMXSize.h"
#import "JMXPoint.h"
#import "NSColor+V8.h"
#import "JMXImageData.h"

@implementation JMXScriptPinWrapper

+ (id)pinWrapperWithName:(NSString *)name
                function:(v8::Persistent<v8::Function>) aFunction
            scriptEntity:(JMXScriptEntity *)entity
{
    return [[[self alloc] initWithName:name
                              function:aFunction
                          scriptEntity:entity] autorelease];
}

+ (id)pinWrapperWithName:(NSString *)name
              statements:(NSString *)statements
            scriptEntity:(JMXScriptEntity *)entity
{
    return [[[self alloc] initWithName:name
                            statements:statements
                          scriptEntity:entity] autorelease];
}

- (id)initWithName:(NSString *)name
          function:(v8::Persistent<v8::Function>) aFunction
      scriptEntity:(JMXScriptEntity *)entity
{
    self = [super initWithName:name];
    if (self) {
        function = aFunction;
        scriptEntity = entity; // weak
    }
    return self;
}

- (id)initWithName:(NSString *)name
        statements:(NSString *)jsStatements
      scriptEntity:(JMXScriptEntity *)entity
{
    self = [super initWithName:name];
    if (self) {
        statements = [jsStatements copy];
        scriptEntity = entity; // weak
    }
    return self;
}

- (void)dealloc
{
    [statements release];
    [virtualPin release];
    [super dealloc];
}

- (void)performSignal:(JMXPinSignal *)signal
{
    
}

- (void)propagateSignal:(id)data
{
    /*
    kJMXVoidPin =    (0),
    kJMXStringPin =  (1),
    kJMXTextPin =    (1<<1),
    kJMXCodePin =    (1<<2),
    kJMXNumberPin =  (1<<3),
    kJMXImagePin =   (1<<4),
    kJMXAudioPin =   (1<<5),
    kJMXPointPin =   (1<<6),
    kJMXSizePin =    (1<<7),
    kJMXRectPin =    (1<<8),
    kJMXColorPin =   (1<<9),
    kJMXBooleanPin = (1<<10)
    */
    Locker locker;
    HandleScope handleScope;
    v8::Context::Scope context_scope(scriptEntity.jsContext.ctx);

    Handle<Value> args[1];
    switch (virtualPin.type) {
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
        case kJMXPointPin:
            args[0] = [(JMXPoint *)data jsObj];
            break;
        default:
            break;
    }
    if (!function.IsEmpty() && !function->IsNull())
        [scriptEntity.jsContext execFunction:function withArguments:args count:1];
    else if (statements)
        [scriptEntity.jsContext execCode:statements];
}

- (void)receivedSignal:(id)data
{
    [self propagateSignal:data];
}

- (void)connectToPin:(JMXPin *)pin
{
    [virtualPin disconnectAllPins];
    [virtualPin release];
    
    if (pin.direction == kJMXOutputPin) {
        virtualPin = [[JMXPin pinWithLabel:@"jsReceiver"
                                       andType:pin.type
                                  forDirection:kJMXInputPin
                                       ownedBy:self
                                    withSignal:@"receivedSignal:"] retain];
        [pin connectToPin:virtualPin];
    } else {
        virtualPin = [[JMXPin pinWithLabel:@"jsProducer"
                                  andType:pin.type
                             forDirection:kJMXOutputPin
                                  ownedBy:self
                               withSignal:@"performSignal:"] retain];
    }
    [pin connectToPin:virtualPin];
}


- (void)disconnect
{
    [virtualPin disconnectAllPins];
}

static v8::Handle<Value>disconnect(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXScriptPinWrapper *wrapper = (JMXScriptPinWrapper *)args.Holder()->GetPointerFromInternalField(0);
    [wrapper disconnect];
    [pool release];
    return Undefined();
}

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("PinWrapper"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("disconnect", FunctionTemplate::New(disconnect));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);

    //instanceTemplate->SetAccessor(String::NewSymbol("owner"), accessObjectProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    NSDebug(@"JMXScriptPinWrapper objectTemplate created");
    return objectTemplate;
}

static void JMXScriptPinWrapperJSDestructor(Persistent<Value> object, void *parameter)
{
    HandleScope handle_scope;
    v8::Locker lock;
    JMXScriptPinWrapper *obj = static_cast<JMXScriptPinWrapper *>(parameter);
    //NSLog(@"V8 WeakCallback (Point) called %@", obj);
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
    HandleScope handleScope;
    v8::Persistent<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Persistent<Object> jsInstance = v8::Persistent<Object>::New(objectTemplate->InstanceTemplate()->NewInstance());
    jsInstance.MakeWeak([self retain], JMXScriptPinWrapperJSDestructor);
    jsInstance->SetPointerInInternalField(0, self);
    return handleScope.Close(jsInstance);
}

@end
