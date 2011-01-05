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
#import "JMXProxyPin.h"

JMXV8_EXPORT_NODE_CLASS(JMXEntity);

using namespace v8;

@implementation JMXEntity

@synthesize label, active;

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
        self.name = @"Entity";
        self.label = @"";
        active = NO;
        inputPins = [[NSXMLNode elementWithName:@"inputPins"] retain];
        [self addChild:inputPins];
        outputPins = [[NSXMLNode elementWithName:@"outputPins"] retain];
        [self addChild:outputPins];
        [self addAttribute:[NSXMLNode attributeWithName:@"class" stringValue:NSStringFromClass([self class])]];
        [self addAttribute:[NSXMLNode attributeWithName:@"label" stringValue:label]];
        [self addAttribute:[NSXMLNode attributeWithName:@"active" stringValue:@"NO"]];
        activeIn = [self registerInputPin:@"active" withType:kJMXBooleanPin andSelector:@"setActivePin:"  allowedValues:nil initialValue:[NSNumber numberWithBool:NO]];
        activeOut = [self registerOutputPin:@"active" withType:kJMXBooleanPin];
        [self registerInputPin:@"name" withType:kJMXStringPin andSelector:@"setEntityName:"];
        // delay notification so that the superclass constructor can finish its job
        // since this selector is going to be called in this same thread, we know for sure
        // that it's going to be called after the init-chain has been fully executed
        // NOTE: since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
        [self performSelectorOnMainThread:@selector(notifyCreation) withObject:nil waitUntilDone:NO];
        privateData = [[[NSMutableDictionary alloc] init] retain];
    }
    return self;
}

- (void)release
{
    // the context retains us in the DOM so we need to
    // check if that will be the only one retaining us
    // after this release operation.
    if ([self retainCount] == 2 && self.parent)
        [self detach];
    [super release];
}

- (void)dealloc
{
    // We need notifications to be delivered on the thread where
    // the GUI runs (otherwise it won't catch the notification)
    // but we also need to wait until all notifications have been
    // sent to observers otherwise we would release ourselves before
    // their execution (which will happen in the main thread) 
    // so an invalid object will be accessed and a crash will occur
    [self disconnectAllPins];
    for (JMXInputPin *pin in [inputPins children]) {
        [pin detach];
        // as explained above ... we need to wait until done
        [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:YES];
    }
    for (JMXOutputPin *pin in [outputPins children]) {
        [pin detach];
        // as explained above ... we need to wait until done
        [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:YES];
    }
    // as explained above ... we need to wait until done
    [self performSelectorOnMainThread:@selector(notifyRelease) withObject:nil waitUntilDone:YES];
    [inputPins detach];
    [inputPins release];
    [outputPins detach];
    [outputPins release];
    [privateData release];
    NSLog(@"Released %@", self);
    [super dealloc];
}

- (void)defaultInputCallback:(id)inputData
{
    
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(JMXPinType)pinType
{
    return [self registerInputPin:pinName withType:pinType andSelector:@"defaultInputCallback:"];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
{
    return [self registerInputPin:pinName
                         withType:pinType
                      andSelector:selector
                    allowedValues:nil
                     initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
{
    return [self registerInputPin:pinName
                         withType:pinType
                      andSelector:selector
                         userData:userData
                    allowedValues:nil 
                     initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    
    JMXInputPin *newPin = [JMXPin pinWithName:pinName
                                      andType:pinType
                                 forDirection:kJMXInputPin
                                      ownedBy:self
                                   withSignal:selector
                                     userData:userData
                                allowedValues:pinValues
                                 initialValue:(id)value];
    [inputPins addChild:newPin];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
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

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
{
    return [self registerOutputPin:pinName
                          withType:pinType
                       andSelector:selector
                          userData:userData
                     allowedValues:nil
                      initialValue:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    JMXOutputPin *newPin = [JMXPin pinWithName:pinName
                                       andType:pinType
                                  forDirection:kJMXOutputPin
                                       ownedBy:self
                                    withSignal:selector
                                      userData:userData
                                 allowedValues:pinValues
                                  initialValue:(id)value];
    [outputPins addChild:newPin];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
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

- (void)proxyInputPin:(JMXInputPin *)pin withName:(NSString *)pinName
{
    JMXProxyPin *pPin = [JMXProxyPin proxyPin:pin withName:pinName ? pinName : pin.name];
    [inputPins addChild:(JMXPin *)pPin];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:pPin waitUntilDone:NO];
}

- (void)proxyInputPin:(JMXInputPin *)pin
{
    return [self proxyInputPin:pin withName:nil];
}

- (void)proxyOutputPin:(JMXOutputPin *)pin withName:(NSString *)pinName
{
    JMXProxyPin *pPin = [JMXProxyPin proxyPin:pin withName:pinName ? pinName : pin.name];
    [outputPins addChild:(JMXPin *)pPin];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:pPin waitUntilDone:NO];
}

- (void)proxyOutputPin:(JMXOutputPin *)pin
{
    return [self proxyOutputPin:pin withName:nil];
}

// XXX - possible race conditions here (in both inputPins and outputPins)
- (NSArray *)inputPins
{
    /*
    return [[inputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];*/
    return [[inputPins children] sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [[obj1 name] compare:[obj2 name]];
            }];
}

- (NSArray *)outputPins
{
    return [[outputPins children]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [[obj1 name] compare:[obj2 name]];
            }];
}

- (JMXInputPin *)inputPinWithName:(NSString *)pinName
{
    return [[inputPins elementsForName:pinName] lastObject];
}

- (JMXOutputPin *)outputPinWithName:(NSString *)pinName
{
    return [[outputPins elementsForName:pinName] lastObject];
}

- (void)unregisterInputPin:(NSString *)pinName
{
    JMXInputPin *pin = [[[inputPins elementsForName:pinName] lastObject]retain];
    if (pin && pin.owner == self) {
        [pin disconnectAllPins];
        [pin detach];
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
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
    JMXOutputPin *pin = [[outputPins elementsForName:pinName] lastObject];
    if (pin && pin.owner == self) { // don't touch it if the pin is proxed
        [pin disconnectAllPins];
    }
    [pin detach];
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:NO];
    // we can now release the pin
    [pin release];
}

- (void)unregisterAllPins
{
    [self disconnectAllPins];
    for (JMXInputPin *pin in [inputPins children])
        [self unregisterInputPin:pin.name];

    for (JMXOutputPin *pin in [outputPins children])
        [self unregisterOutputPin:pin.name];
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
    for (JMXInputPin *pin in [inputPins children])
        [pin disconnectAllPins];
    for (JMXOutputPin *pin in [outputPins children])
        [pin disconnectAllPins];
}

- (NSString *)description
{
    return (!label || [label isEqual:@""])
           ? self.name
           : [NSString stringWithFormat:@"%@:%@", self.name, label];
}

- (void)activate
{
    self.active = YES;
}

- (void)deactivate
{
    self.active = NO;
}

- (void)setActivePin:(NSNumber *)value
{
    self.active = [value boolValue];
}

- (id)privateDataForKey:(NSString *)key
{
    @synchronized(privateData) {
        return [[[privateData objectForKey:key] retain] autorelease];
    }
}

- (void)addPrivateData:(id)data forKey:(NSString *)key
{
    @synchronized(privateData) {
        [privateData setObject:data forKey:key];
    }
}

- (void)removePrivateDataForKey:(NSString *)key
{
    @synchronized(privateData) {
        [privateData removeObjectForKey:key];
    }
}

/*
- (void)setName:(NSString *)newName
{
    if (name)
        [name release];
    name = [[NSString stringWithFormat:@"%@:%@", [self class], newName] retain];
}
*/

- (void)setLabel:(NSString *)newLabel
{
    if (label)
        [label release];
    label = [newLabel copy];
    NSXMLNode *attr = [self attributeForName:@"label"];
    [attr setStringValue:label];
}

- (void)setActive:(BOOL)newActive
{
    active = newActive;
    NSXMLNode *attr = [self attributeForName:@"active"];
    [attr setStringValue:active ? @"YES" : @"NO"];
    activeOut.data = [NSNumber numberWithBool:active];
}

#pragma mark <JMXPinOwner>

- (id)provideDataToPin:(JMXPin *)aPin
{
    // TODO - use introspection to determine the return type of a message
    //        to generalize using encapsulation in NSNumber/NSData/NSValue
    // XXX - it seems not possible ... further digging is required
    if ([aPin.name isEqualTo:@"active"]) {
        return [NSNumber numberWithBool:self.active];
    } else {
        SEL selector = NSSelectorFromString(aPin.name);
        if ([self respondsToSelector:selector]) {
            return [[[self performSelector:selector] retain] autorelease];
        }
    }
    return nil;
}

- (void)receiveData:(id)data fromPin:(JMXPin *)aPin
{
    // XXX - base implementation doesn't do anything
}

#pragma mark V8

- (void)jsInit:(NSValue *)argsValue
{
    // do nothing, our subclasses could use this to do something with
    // arguments passed to the constructor
}

#pragma mark Accessors

static v8::Handle<Value>InputPins(Local<String> name, const AccessorInfo& info)
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

static v8::Handle<Value>OutputPins(Local<String> name, const AccessorInfo& info)
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


static v8::Handle<Value> InputPin(const Arguments& args)
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
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> OutputPin(const Arguments& args)
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
    return handleScope.Close(Undefined());
}

#pragma mark Class Template

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Entity"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("inputPin", FunctionTemplate::New(InputPin));
    classProto->Set("outputPin", FunctionTemplate::New(OutputPin));
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("description"), GetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("inputPins"), InputPins);
    instanceTemplate->SetAccessor(String::NewSymbol("outputPins"), OutputPins);
    instanceTemplate->SetAccessor(String::NewSymbol("active"), GetBoolProperty, SetBoolProperty);
    
    if ([self respondsToSelector:@selector(jsObjectTemplateAddons:)])
        [self jsObjectTemplateAddons:objectTemplate];
    NSLog(@"JMXEntity objectTemplate created");
    return objectTemplate;
}

static v8::Handle<Value> NativeClassName(const Arguments& args)
{   
    //v8::Locker lock;
    HandleScope handleScope;
    Class objcClass = (Class)External::Unwrap(args.Holder()->Get(String::NewSymbol("_objcClass")));
    if (objcClass)
        return handleScope.Close(String::New([NSStringFromClass(objcClass) UTF8String]));
    return v8::Undefined();
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    constructor->InstanceTemplate()->SetInternalFieldCount(1);
    //constructor->InstanceTemplate()->SetPointerInInternalField(0, self);
    PropertyAttribute attrs = DontEnum;
    constructor->Set(String::NewSymbol("_objcClass"), External::Wrap(self), attrs);
    constructor->Set("nativeClassName", FunctionTemplate::New(NativeClassName));
}

@end

