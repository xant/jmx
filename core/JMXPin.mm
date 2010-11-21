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

#import "JMXPin.h"
#import "JMXContext.h"
#import "JMXOutputPin.h"
#import "JMXInputPin.h"
#import <v8.h>
#import "JMXScript.h"
#import "JMXEntity.h"

using namespace v8;

@implementation JMXPin

@synthesize type, name, multiple, continuous, connected, sendNotifications,
            direction, allowedValues, owner, minValue, maxValue;

#pragma mark Constructors

+ (id)pinWithName:(NSString *)name
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
    return [[[pinClass alloc]     initWithName:name
                                       andType:pinType
                                       ownedBy:pinOwner
                                    withSignal:pinSignal
                                      userData:userData
                                 allowedValues:pinValues
                                  initialValue:value]
            autorelease];
}

+ (id)pinWithName:(NSString *)name
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
    return  [pinClass pinWithName:name
                              andType:pinType
                         forDirection:pinDirection
                              ownedBy:pinOwner
                           withSignal:pinSignal
                             userData:userData
                        allowedValues:pinValues
                         initialValue:nil];
}

+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
{
    id pinClass = pinDirection == kJMXInputPin
    ? [JMXInputPin class]
    : [JMXOutputPin class];
    return [pinClass pinWithName:name
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:nil
                   allowedValues:nil];
}

+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
{
    id pinClass = pinDirection == kJMXInputPin
                ? [JMXInputPin class]
                : [JMXOutputPin class];
    return [pinClass pinWithName:name
                         andType:pinType
                    forDirection:pinDirection
                         ownedBy:pinOwner
                      withSignal:pinSignal
                        userData:userData
                   allowedValues:nil];
}

#pragma mark Initializers

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
{
    return [self initWithName:name
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:nil
                allowedValues:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
{
    return [self initWithName:name
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
{
    return [self initWithName:pinName
                      andType:pinType
                      ownedBy:pinOwner
                   withSignal:pinSignal
                     userData:userData
                allowedValues:pinValues
                 initialValue:nil];
}

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value
{
    self = [super init];
    if (self) {
        type = pinType;
        name = [pinName retain];
        multiple = NO;
        continuous = YES;
        connected = NO;
        currentSender = nil;
        owner = pinOwner;
        ownerSignal = pinSignal;
        ownerUserData = userData;
        sendNotifications = YES;
        if (pinValues)
            allowedValues = [[NSMutableArray arrayWithArray:pinValues] retain];
        rOffset = wOffset = 0;
        if (value && [self isCorrectDataType:value]) {
            currentSender = owner;
            dataBuffer[wOffset++] = [value retain];
        }
        writersLock = [[NSRecursiveLock alloc] init];
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
    [name release];
    if (allowedValues)
        [allowedValues release];
    [writersLock release];
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
    return [NSString stringWithFormat:@"%@:%@", ownerName, name];
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

- (void)addMinLimit:(id)value
{
    if ([self isCorrectDataType:value])
        minValue = [value retain];
}

- (void)addMaxLimit:(id)value
{
    if ([self isCorrectDataType:value])
        maxValue = [value retain];
}

- (id)readData
{
    id data = [dataBuffer[rOffset&kJMXPinDataBufferMask] retain];
    return [data autorelease];
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

- (void)deliverData:(id)data fromSender:(id)sender
{

    // check if NULL data has been signaled
    // and if it's the case, clear currentData and return
    if (!data) {
        return;
    }
    // if instead new data arrived, check if it's of the correct type
    // and propagate the signal if that's the case
    if ([self isCorrectDataType:data]) {
        // check if we restrict possible values
        if (allowedValues && ![allowedValues containsObject:data]) {
            // TODO - Error Message (a not allowed value has been signaled
            return;
        }
        // this lock protects us from multiple senders delivering a signal at the exact same time
        // wOffset and rOffset must both be incremented in an atomic operation.
        // concurrency here can happen only in 2 scenarios :
        // - an input pin which allows multiple producers (like mixers)
        // - when the user connect a new producer a signal is sent, and the signal from
        //   current producer could still being executed.
        // TODO - try to get rid of this lock
        [writersLock lock]; // in single-producer mode, this lock will always be free to lock
        dataBuffer[wOffset&kJMXPinDataBufferMask] = [data retain];
        if (wOffset > rOffset) {
            UInt32 off = rOffset++;
            [dataBuffer[off&kJMXPinDataBufferMask] release];
        }
        wOffset++;
        [writersLock unlock];

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
    if (direction == kJMXInputPin && ownerSignal)
        [self sendData:signal.data toReceiver:signal.receiver withSelector:ownerSignal fromSender:signal.sender];
    [pool drain];
}

- (BOOL)canConnectToPin:(JMXPin *)pin
{
    return (type == pin.type && direction != pin.direction) ? YES : NO;
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
    v8::Local<Context> globalContext = v8::Context::GetCalling();
    JMXScript *ctx = [JMXScript getContext:globalContext];
    if (ctx && ctx.scriptEntity) {        
        if (pin.direction == kJMXInputPin)
            [ctx.scriptEntity proxyInputPin:(JMXInputPin *)pin];
        else 
            [ctx.scriptEntity proxyOutputPin:(JMXOutputPin *)pin];
        ret = YES;
    }
    return scope.Close(v8::Boolean::New(ret));
}

static v8::Persistent<FunctionTemplate> classTemplate;

+ (v8::Persistent<FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    //v8::Handle<FunctionTemplate> classTemplate = FunctionTemplate::New();
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXPin ClassTemplate created");
    classTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->SetClassName(String::New("Pin"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classProto->Set("connect", FunctionTemplate::New(connect));
    classProto->Set("export", FunctionTemplate::New(exportToBoard));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = classTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("type"), type);
    instanceTemplate->SetAccessor(String::NewSymbol("direction"), direction);
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("multiple"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("continuous"), GetBoolProperty, SetBoolProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("owner"), accessObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("minValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("maxValue"), GetObjectProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("connected"), GetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("sendNotifications"), GetBoolProperty, SetBoolProperty);
    //instanceTemplate->SetAccessor(String::NewSymbol("allowedValues"), allowedValues);
    return classTemplate;
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handleScope;
    v8::Persistent<FunctionTemplate> classTemplate = [JMXPin jsClassTemplate];
    v8::Handle<Object> jsInstance = classTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handleScope.Close(jsInstance);
}

@end

