//
//  JMXConnector.m
//  JMX
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#define __JMXV8__
#import "JMXPin.h"
#import "JMXContext.h"
#import "JMXOutputPin.h"
#import "JMXInputPin.h"
#import "JMXScript.h"
#import "JMXEntity.h"

using namespace v8;

@implementation JMXPin

@synthesize type, label, multiple, continuous, connected, sendNotifications,
            direction, allowedValues, owner, minValue, maxValue, connections;

#pragma mark Constructors

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)pinValues
     initialValue:(id)value

{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [[[pinClass alloc]     initWithLabel:label
                                       andType:pinType
                                       ownedBy:pinOwner
                                    withSignal:pinSignal
                                      userData:userData
                                 allowedValues:pinValues
                                  initialValue:value]
            autorelease];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
     withSignal:(NSString *)pinSignal
     userData:(id)userData
  allowedValues:(NSArray *)pinValues
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return  [pinClass pinWithLabel:label
                              andType:pinType
                         forDirection:pinDirection
                              ownedBy:pinOwner
                           withSignal:pinSignal
                             userData:userData
                        allowedValues:pinValues
                         initialValue:nil];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [pinClass pinWithLabel:label
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:nil
                   allowedValues:nil];
}

+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [pinClass pinWithLabel:label
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:userData
                   allowedValues:nil];
}

#pragma mark Initializers

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:nil
                allowedValues:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
{
    return [self initWithLabel:pinLabel
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:pinValues
                 initialValue:nil];
}

- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    self = [super initWithName:@"JMXPin"];
    if (self) {
        type = pinType;
        label = [pinLabel copy];
        multiple = NO;
        continuous = YES;
        connected = NO;
        currentSender = nil;
        owner = pinOwner;
        ownerSignal = [pinSignal copy];
        ownerUserData = userData;
        sendNotifications = YES;
        memset(dataBuffer, 0, sizeof(dataBuffer));
        allowedValues = pinValues ? [[NSMutableArray arrayWithArray:pinValues] retain] : nil;
        rOffset = wOffset = 0;
        if (value && [self isCorrectDataType:value]) {
            currentSender = owner;
            dataBuffer[wOffset++] = [value retain];
        }
        dataLock = [[NSRecursiveLock alloc] init];
        [self addAttribute:[NSXMLNode attributeWithName:@"type" stringValue:[JMXPin nameforType:type]]];
        [self addAttribute:[NSXMLNode attributeWithName:@"multiple" stringValue:multiple ? @"YES" : @"NO" ]];
        [self addAttribute:[NSXMLNode attributeWithName:@"connected" stringValue:connected ? @"YES" : @"NO" ]];
        [self addAttribute:[NSXMLNode attributeWithName:@"label" stringValue:label]];
        connections = [[JMXElement alloc] initWithName:@"connections"];
        [self addChild:connections];
    }
    return self;
}

- (id)init
{
    // bad usage
    [self dealloc];
    return nil;
}

#pragma mark Implementation

+ (NSString *)nameforType:(JMXPinType)type
{
    switch (type) {
        case kJMXStringPin:
            return @"String";
        case kJMXTextPin:
            return @"Text";
        case kJMXNumberPin:
            return @"Number";
        case kJMXImagePin:
            return @"Image";
        case kJMXSizePin:
            return @"Size";
        case kJMXPointPin:
            return @"Point";
        case kJMXAudioPin:
            return @"Audio";
        case kJMXColorPin:
            return @"Color";
        case kJMXBooleanPin:
            return @"Boolean";
    }
    return nil;
}

- (BOOL)isCorrectDataType:(id)data
{
    switch (type) {
        case kJMXStringPin:
        case kJMXTextPin:
            if (![data isKindOfClass:[NSString class]])
                return NO;
            break;
        case kJMXBooleanPin:
            if ([[data className] isEqualToString:@"NSCFBoolean"] || [data isKindOfClass:[NSNumber class]])
                return YES;
            return NO;
            break;
        case kJMXNumberPin:
            if ([[data className] isEqualToString:@"NSCFNumber"] || [data isKindOfClass:[NSNumber class]])
                return YES;
            return NO;
            break;
        case kJMXImagePin:
            if (![data isKindOfClass:[CIImage class]])
                return NO;
            break;
        case kJMXSizePin:
            if (![data isKindOfClass:[JMXSize class]])
                return NO;
            break;
        case kJMXPointPin:
            if (![data isKindOfClass:[JMXPoint class]])
                return NO;
            break;
        case kJMXAudioPin:
            if (![data isKindOfClass:[JMXAudioBuffer class]])
                return NO;
            break;
        case kJMXColorPin:
            if (![data isKindOfClass:[NSColor class]])
                return NO;
            break;
        default:
            NSLog(@"Unknown pin type!\n");
            return NO;
    }
    return YES;
}

- (void)allowMultipleConnections:(BOOL)choice
{
    multiple = choice;
}

- (void)dealloc
{
    [connections detach];
    [connections release];
    [label release];
    if (allowedValues)
        [allowedValues release];
    [dataLock release];
    [super dealloc];
}

- (BOOL)connectToPin:(JMXPin *)destinationPin
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
    // send a connect notification for all involved pins
    if (self.sendNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                            object:self
                                                          userInfo:userInfo];
    }
    if (destinationPin.sendNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinConnected"
                                                            object:destinationPin
                                                          userInfo:userInfo];
    }
    return YES;
}

- (void)disconnectFromPin:(JMXPin *)destinationPin
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:destinationPin, @"outputPin", self, @"inputPin", nil];
    // send a disconnect notification for all the involved pins
    if (self.sendNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                            object:self
                                                          userInfo:userInfo];
    }
    if (destinationPin.sendNotifications) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXPinDisconnected"
                                                            object:destinationPin
                                                          userInfo:userInfo];
    }
}

- (void)disconnectAllPins
{

}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (NSString *)typeName
{
    NSString *aName = [JMXPin nameforType:type];
    if (aName)
        return aName;
    return @"Unknown";
}

- (NSString *)description
{
    NSString *ownerName;
    if ([owner respondsToSelector:@selector(name)])
        ownerName = [owner performSelector:@selector(name)];
    return [NSString stringWithFormat:@"%@:%@", ownerName, label];
}

- (void)addAllowedValue:(id)value
{
    if ([self isCorrectDataType:value]) {
        if (!allowedValues)
            allowedValues = [[NSMutableArray alloc] init];
        [allowedValues addObject:value];
    }
}

- (void)addAllowedValues:(NSArray *)values
{
    for (id value in values)
        [self addAllowedValue:value];
}

- (void)removeAllowedValue:(id)value
{
    if ([self isCorrectDataType:value] && allowedValues) {
        [allowedValues removeObject:value];
        if ([allowedValues count] == 0) {
            [allowedValues release];
            allowedValues = nil;
        }
    }
}

- (void)removeAllowedValues:(NSArray *)values
{
    for (id value in values)
        [self removeAllowedValue:value];
}

- (void)setMinLimit:(id)value
{
    if ([self isCorrectDataType:value])
        minValue = [value retain];
}

- (void)setMaxLimit:(id)value
{
    if ([self isCorrectDataType:value])
        maxValue = [value retain];
}

- (id)readData
{
    // if we have an owner which conforms to the <JMXPinOwner> protocol
    // we will send it a message to get the actual value
    id ret = nil;
    if (owner && [owner conformsToProtocol:@protocol(JMXPinOwner)])
        ret = [owner provideDataToPin:self];
    if (!ret) {
        // otherwise we will return the last signaled data
        [dataLock lock];
        ret = [dataBuffer[rOffset&kJMXPinDataBufferMask] retain];
        [dataLock unlock];
        [ret autorelease];
    }
    return ret;
}

- (void)deliverData:(id)data
{
    [self deliverData:data fromSender:self];
}

- (void)sendData:(id)data toReceiver:(id)receiver withSelector:(NSString *)selectorName fromSender:(id)sender
{
    SEL selector = NSSelectorFromString(selectorName);
    int selectorArgsNum = [[selectorName componentsSeparatedByString:@":"] count]-1;
    // checks are now done when registering receivers
    // so we can avoid checking again now if receiver responds to selector and
    // if the selector expects the correct amount of arguments.
    // this routine is expected to deliver the signals as soon as possible
    // all safety checks must be done before putting new objects in the receivers' table
    switch (selectorArgsNum) {
        case 0:
            // some listener could be uninterested to the data,
            // but just want to get notified when something travels on a pin
            [receiver performSelector:selector withObject:nil];
            break;
        case 1:
            // some other listeners could be interested only in the data,
            // regardless of the sender
            [receiver performSelector:selector withObject:data];
            break;
        case 2:
            [receiver performSelector:selector withObject:data withObject:ownerUserData];
            break;
        default:
            NSLog(@"Unsupported selector : '%@' . It can take up to two arguments\n", selectorName);
    }
}

- (BOOL)isValidData:(id)data
{
    if(![self isCorrectDataType:data])
        return NO;
    // check if we restrict possible values
    if (allowedValues && ![allowedValues containsObject:data]) {
        // TODO - Error Message (a not allowed value has been signaled
        return NO;
    }
    switch (self.type) {
        case kJMXNumberPin:
            break;
        case kJMXStringPin:
            break;
        case kJMXSizePin:
            break;
        case kJMXPointPin:
            break;
            
    }
    return YES;
}

- (void)deliverData:(id)data fromSender:(id)sender
{

    // check if NULL data has been signaled
    // and if it's the case, clear currentData and return
    if (!data) {
        return;
    }
    // if instead new data arrived, check if it's of the correct type
    // and propagate the signal if that's the case
    if ([self isValidData:data]) {

        
        // this lock protects us from multiple senders delivering a signal at the exact same time
        // wOffset and rOffset must both be incremented in an atomic operation.
        // concurrency here can happen only in 2 scenarios :
        // - an input pin which allows multiple producers (like mixers)
        // - when the user connect a new producer a signal is sent, and the signal from
        //   current producer could still being executed.
        [dataLock lock]; // in single-producer mode, this lock will always be free to lock
        UInt32 wOff = wOffset&kJMXPinDataBufferMask;
        if (rOffset != wOffset) {
            UInt32 rOff = rOffset++&kJMXPinDataBufferMask;
            [dataBuffer[rOff] release];
        }
        dataBuffer[wOff] = [data retain];
        wOffset++;
        [dataLock unlock];

        // XXX - sender is not protected by a lock
        if (sender)
            currentSender = sender;
        else
            currentSender = self;
        JMXPinSignal *signal = [JMXPinSignal signalFromSender:sender receiver:owner data:data];

#if USE_NSOPERATIONS
        NSBlockOperation *signalDelivery = [NSBlockOperation blockOperationWithBlock:^{
            [self performSignal:signal];
        }];
        [signalDelivery setQueuePriority:NSOperationQueuePriorityVeryHigh];
        [signalDelivery setThreadPriority:1.0];
        [[JMXContext operationQueue] addOperation:signalDelivery];
#else
        [self performSelector:@selector(performSignal:) onThread:[JMXContext signalThread] withObject:signal waitUntilDone:NO];
#endif
    }
}

- (void)performSignal:(JMXPinSignal *)signal
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    // send the signal to our owner
    // (if we are an input pin and if our owner registered a selector)
    if (direction == kJMXInputPin) {
        if (owner) {
            if (ownerSignal)
                [self sendData:signal.data toReceiver:signal.receiver withSelector:ownerSignal fromSender:signal.sender];
            else if ([owner conformsToProtocol:@protocol(JMXPinOwner)])
                [owner performSelector:@selector(receiveData:fromPin:) withObject:signal.data withObject:self];
    
        }
    }
    [pool drain];
}

- (BOOL)canConnectToPin:(JMXPin *)pin
{
    return (type == pin.type && direction != pin.direction) ? YES : NO;
}

- (id)data
{
    return [self readData];
}

- (void)setData:(id)data
{
    [self deliverData:data fromSender:self];
}

#pragma mark V8

static v8::Handle<Value>direction(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXPin *pin = (JMXPin *)info.Holder()->GetPointerFromInternalField(0);
    v8::Handle<String> ret = String::New((pin.direction == kJMXInputPin) ? "input" : "output");
    return handle_scope.Close(ret);
}

static v8::Handle<Value>type(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXPin *pin = (JMXPin *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *typeName = [pin typeName];
    v8::Handle<String> ret = String::New([typeName UTF8String], [typeName length]);
    [pool drain];
    return handle_scope.Close(ret);
}

static v8::Handle<Value>connect(const Arguments& args)
{
    //v8::Locker lock;
    BOOL ret = NO;
    HandleScope handleScope;
    JMXPin *pin = (JMXPin *)args.Holder()->GetPointerFromInternalField(0);
    if (args[0]->IsObject()) {
        String::Utf8Value str(args[0]->ToString());
        if (strcmp(*str, "[object Pin]") == 0) {
            v8::Handle<Object> object = args[0]->ToObject();
            JMXPin *dest = (JMXPin *)object->GetPointerFromInternalField(0);
            if (dest) {
                NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
                ret = [pin connectToPin:dest];
                [pool release];
            }
        } else {
            NSLog(@"Pin::connect(): Bad param %s (should have been a Pin object)", *str);
        }
    } else {
        NSLog(@"Pin::connect(): argument is not an object");
    }
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value>exportToBoard(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope scope;
    BOOL ret = NO;
    JMXPin *pin = (JMXPin *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *label = nil;
    if (!arg.IsEmpty()) {
        v8::String::Utf8Value value(args[0]);
        label = [NSString stringWithUTF8String:*value];
    }
    v8::Local<Context> globalContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext:globalContext];
    if (ctx && ctx.scriptEntity) {        
        if (pin.direction == kJMXInputPin)
            [ctx.scriptEntity proxyInputPin:(JMXInputPin *)pin withLabel:label];
        else 
            [ctx.scriptEntity proxyOutputPin:(JMXOutputPin *)pin withLabel:label];
        ret = YES;
    }
    [pool release];
    return scope.Close(v8::Boolean::New(ret));
}

static v8::Persistent<FunctionTemplate> objectTemplate;

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Pin"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("connect", FunctionTemplate::New(connect));
    classProto->Set("export", FunctionTemplate::New(exportToBoard));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("label"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("type"), type);
    instanceTemplate->SetAccessor(String::NewSymbol("direction"), direction);
    instanceTemplate->SetAccessor(String::NewSymbol("multiple"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("continuous"), GetBoolProperty, SetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("minValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("maxValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("connected"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("sendNotifications"), GetBoolProperty, SetBoolProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("owner"), accessObjectProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    NSLog(@"JMXPin objectTemplate created");
    return objectTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Persistent<FunctionTemplate> objectTemplate = [JMXPin jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handleScope.Close(jsInstance);
}


@end

