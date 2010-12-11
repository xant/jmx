//
//  JMXObject.m
//  JMX
//
//  Created by xant on 9/1/10.
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

#define __JMXV8__ 1
#import "JMXEntity.h"
#import <QuartzCore/QuartzCore.h>
#import "JMXScript.h"

using namespace v8;

@implementation JMXEntity

@synthesize name, active;

- (void)notifyModifications
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityWasModified" object:self];
}

- (void)notifyCreation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityWasCreated" object:self];
}

- (void)notifyRelease
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityWasDestroyed" object:self];
}

- (void)notifyPinAdded:(JMXPin *)pin
{
    NSString *notificationName = (pin.direction == kJMXInputPin)
                               ? @"JMXEntityInputPinAdded"
                               : @"JMXEntityOutputPinAdded";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pin.name, @"pinName", nil];

    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)notifyPinRemoved:(JMXPin *)pin
{
    NSString *notificationName = (pin.direction == kJMXInputPin)
                               ? @"JMXEntityInputPinRemoved"
                               : @"JMXEntityOutputPinRemoved";
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pin.name, @"pinName", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName 
                                                        object:self
                                                      userInfo:userInfo];
}

- (id)init
{
    // TODO - start using debug messages activated by some flag
    //NSLog(@"Initializing %@", [self class]);
    self = [super init];
    if (self) {
        self.name = [self description];
        inputPins = [[NSMutableDictionary alloc] init];
        outputPins = [[NSMutableDictionary alloc] init];
        [self registerInputPin:@"active" withType:kJMXNumberPin andSelector:@"setActivePin:"];
        [self registerOutputPin:@"active" withType:kJMXNumberPin];
        [self registerInputPin:@"name" withType:kJMXStringPin andSelector:@"setName:" ];
        // delay notification so that the superclass constructor can finish its job
        // since this selector is going to be called in this same thread, we know for sure
        // that it's going to be called after the init-chain has been fully executede
        [self performSelectorOnMainThread:@selector(notifyCreation) withObject:nil waitUntilDone:NO];
    }
    return self;
}

- (void)dealloc
{
    [self performSelectorOnMainThread:@selector(notifyRelease) withObject:nil waitUntilDone:YES];
    [self unregisterAllPins];
    [inputPins release];
    [outputPins release];
    [super dealloc];
}

- (void)defaultInputCallback:(id)inputData
{
    
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName withType:(JMXPinType)pinType
{
    return [self registerInputPin:pinName withType:pinType andSelector:@"defaultInputCallback:"];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName withType:(JMXPinType)pinType andSelector:(NSString *)selector
{
    return [self registerInputPin:pinName withType:pinType andSelector:selector allowedValues:nil initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName withType:(JMXPinType)pinType andSelector:(NSString *)selector userData:(id)userData
{
    return [self registerInputPin:pinName withType:pinType andSelector:selector userData:userData allowedValues:nil initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    [inputPins setObject:[JMXPin pinWithName:pinName
                                     andType:pinType
                                forDirection:kJMXInputPin
                                     ownedBy:self
                                  withSignal:selector
                                    userData:userData
                               allowedValues:pinValues
                                initialValue:(id)value]
                  forKey:pinName];
    JMXInputPin *newPin = [inputPins objectForKey:pinName];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:newPin waitUntilDone:NO];
    return newPin;
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    return [self registerInputPin:pinName
                         withType:pinType
                      andSelector:selector
                         userData:nil
                    allowedValues:pinValues
                     initialValue:value];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName withType:(JMXPinType)pinType
{
    return [self registerOutputPin:pinName withType:pinType andSelector:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
{
    return [self registerOutputPin:pinName
                          withType:pinType
                       andSelector:selector
                     allowedValues:nil
                      initialValue:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName withType:(JMXPinType)pinType andSelector:(NSString *)selector userData:(id)userData
{
    return [self registerOutputPin:pinName withType:pinType andSelector:selector userData:userData allowedValues:nil initialValue:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    [outputPins setObject:[JMXPin pinWithName:pinName
                                      andType:pinType
                                 forDirection:kJMXOutputPin
                                      ownedBy:self
                                   withSignal:selector
                                     userData:userData
                                allowedValues:pinValues
                                 initialValue:(id)value]
                   forKey:pinName];
    JMXOutputPin *newPin = [outputPins objectForKey:pinName];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:newPin waitUntilDone:NO];
    return newPin;
}


- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    return [self registerOutputPin:pinName
                          withType:pinType
                       andSelector:selector
                          userData:nil
                     allowedValues:pinValues
                      initialValue:value];
}

- (void)proxyInputPin:(JMXInputPin *)pin
{
    [inputPins setObject:pin
                  forKey:pin.name];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:pin waitUntilDone:NO];
}

- (void)proxyOutputPin:(JMXOutputPin *)pin
{
    [outputPins setObject:pin
                   forKey:pin.name];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:pin waitUntilDone:NO];
}

// XXX - possible race conditions here (in both inputPins and outputPins)
- (NSArray *)inputPins
{
    return [[inputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];
}

- (NSArray *)outputPins
{
    return [[outputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];
}

- (JMXInputPin *)inputPinWithName:(NSString *)pinName
{
    return [inputPins objectForKey:pinName];
}

- (JMXOutputPin *)outputPinWithName:(NSString *)pinName
{
    return [outputPins objectForKey:pinName];
}

- (void)unregisterInputPin:(NSString *)pinName
{
    JMXInputPin *pin = [[inputPins objectForKey:pinName] retain];
    if (pin && pin.owner == self) {
        [inputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:NO];
    [pin release];
}

- (void)outputPinRemoved:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityOutputPinRemoved"
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)unregisterOutputPin:(NSString *)pinName
{
    JMXOutputPin *pin = [[outputPins objectForKey:pinName] retain];
    if (pin && pin.owner == self) { // don't touch it if the pin is proxed
        [outputPins removeObjectForKey:pinName];
        [pin disconnectAllPins];
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:NO];
    // we can now release the pin
    [pin release];
}

- (void)unregisterAllPins
{
    [self disconnectAllPins];
    [inputPins removeAllObjects];
    [outputPins removeAllObjects];
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    JMXOutputPin *activePin = [self outputPinWithName:@"active"];    
    [activePin deliverData:[NSNumber numberWithBool:active] fromSender:self];
}

- (BOOL)attachObject:(id)receiver withSelector:(NSString *)selector toOutputPin:(NSString *)pinName
{
    JMXOutputPin *pin = [self outputPinWithName:pinName];
    if (pin) {
        // create a virtual pin to be attached to the receiver
        // not that the pin will automatically released once disconnected
        JMXInputPin *vPin = [JMXInputPin pinWithName:@"vpin"
                                             andType:pin.type
                                        forDirection:kJMXInputPin
                                             ownedBy:receiver
                                          withSignal:selector];
        [pin connectToPin:vPin];
        return YES;
    }
    return NO;
}

- (id)copyWithZone:(NSZone *)zone
{
    // we don't want copies, but we want to use such objects as keys of a dictionary
    // so we still need to conform to the 'copying' protocol,
    // but since we are to be considered 'immutable' we can adopt what described at the end of :
    // http://developer.apple.com/mac/library/documentation/cocoa/conceptual/MemoryMgmt/Articles/mmImplementCopy.html
    return [self retain];
}

- (void)disconnectAllPins
{
    for (id key in inputPins)
        [[inputPins objectForKey:key] disconnectAllPins];
    for (id key in outputPins)
        [[outputPins objectForKey:key] disconnectAllPins];
}

- (NSString *)description
{
    return (!name || [name isEqual:@""])
           ? [self className]
           : [NSString stringWithFormat:@"%@:%@", [self className], name];
}

- (void)activate
{
    self.active = YES;
}

- (void)deactivate
{
    self.active = NO;
}

- (void)setActivePin:(id)value
{
    self.active = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
    ? YES
    : NO;
}

#pragma mark V8

- (void)jsInit:(NSValue *)argsValue
{
    // do nothing, our subclasses could use this to do something with
    // arguments passed to the constructor
}

#pragma mark Accessors

static v8::Handle<Value>inputPins(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXEntity *entity = (JMXEntity *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *inputPins = [entity inputPins];
    v8::Handle<Array> list = v8::Array::New([inputPins count]);
    int cnt = 0;
    for (NSString *pin in inputPins) {
        list->Set(v8::Number::New(cnt++), String::New([pin UTF8String]));
    }
    [pool drain];
    return handleScope.Close(list);
}

static v8::Handle<Value>outputPins(Local<String> name, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXEntity *entity = (JMXEntity *)info.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *outputPins = [entity outputPins];
    v8::Handle<Array> list = v8::Array::New([outputPins count]);
    int cnt = 0;
    for (NSString *pin in outputPins) {
        list->Set(v8::Number::New(cnt++), String::New([pin UTF8String]));
    }
    [pool drain];
    return handleScope.Close(list);
}


v8::Handle<Value> inputPin(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXEntity *entity = (JMXEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXPin *pin = [entity inputPinWithName:[NSString stringWithUTF8String:*value]];
    if (pin) {
        v8::Handle<Object> pinInstance = [pin jsObj];
        [pool drain];
        return handleScope.Close(pinInstance);
    } else {
        NSLog(@"Entity::inputPin(): %s not found in %@", *value, entity);
    }
    [pool drain];
    return v8::Undefined();
}

v8::Handle<Value> outputPin(const Arguments& args)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    JMXEntity *entity = (JMXEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    Local<Value> ret;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXPin *pin = [entity outputPinWithName:[NSString stringWithUTF8String:*value]];
    if (pin) {
        v8::Handle<Object> pinInstance = [pin jsObj];
        [pool drain];
        return handleScope.Close(pinInstance);
    } else {
        NSLog(@"Entity::outputPin(): %s not found in %@", *value, entity);
    }
    [pool drain];
    return v8::Undefined();
}

#pragma mark Class Template
static Persistent<FunctionTemplate> classTemplate;

+ (v8::Persistent<FunctionTemplate>)jsClassTemplate
{
    //v8::Locker lock;
    if (!classTemplate.IsEmpty())
        return classTemplate;
    NSLog(@"JMXEntity ClassTemplate created");
    classTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->SetClassName(String::New("Entity"));
    v8::Handle<ObjectTemplate> classProto = classTemplate->PrototypeTemplate();
    classProto->Set("inputPin", FunctionTemplate::New(inputPin));
    classProto->Set("outputPin", FunctionTemplate::New(outputPin));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = classTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("name"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("description"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("inputPins"), inputPins);
    instanceTemplate->SetAccessor(String::NewSymbol("outputPins"), outputPins);
    instanceTemplate->SetAccessor(String::NewSymbol("active"), GetBoolProperty, SetBoolProperty);
    return classTemplate;
}

@end

