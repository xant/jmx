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
#import "JMXAttribute.h"
#import "JMXContext.h"
#import "JMXThreadedEntity.h"

JMXV8_EXPORT_NODE_CLASS(JMXEntity);

using namespace v8;

@implementation JMXEntity

@dynamic label, active;
@synthesize owner;

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
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pin.label, @"pinLabel", nil];

    // TODO - deprecated this one
    NSString *notificationName = (pin.direction == kJMXInputPin)
                               ? @"JMXEntityInputPinAdded"
                               : @"JMXEntityOutputPinAdded";
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName
                                                        object:self
                                                      userInfo:userInfo];
    
    // in favour of this more generic notification.
    // Observers can take care of determining if it's an input or output pin by themselves.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityPinAdded" 
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)notifyPinRemoved:(JMXPin *)pin
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:pin, @"pin", pin.label, @"pinLabel", nil];
    
    // TODO - deprecate this one
    NSString *notificationName = (pin.direction == kJMXInputPin)
                               ? @"JMXEntityInputPinRemoved"
                               : @"JMXEntityOutputPinRemoved";
    [[NSNotificationCenter defaultCenter] postNotificationName:notificationName 
                                                        object:self
                                                      userInfo:userInfo];
    // in favour of this more generic notification.
    // Observers can take care of determining if it's an input or output pin by themselves.
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityPinRemoved" 
                                                        object:self
                                                      userInfo:userInfo];
}
/*
- (id)jmxInit:(id)arg
{
    self = [super jmxInit:arg];
    if (self) {
        if ([arg isKindOfClass:[JMXEntity class]]) {
            // we have been created from javascript
            owner = arg;
            if (owner) {
                [self detach];
                @synchronized(owner) {
                    [owner addChild:self];
                }
            }
        }
    }
    return self;
}
*/

- (id)init
{
    // TODO - start using debug messages activated by some flag
    //NSLog(@"Initializing %@", [self class]);
    self = [super init];
    if (self) {
        owner = nil;
        self.name = @"JMXEntity";
        self.label = @"";
        active = NO;
        [self addAttribute:[JMXAttribute attributeWithName:@"class" stringValue:NSStringFromClass([self class])]];
        [self addAttribute:[JMXAttribute attributeWithName:@"label" stringValue:label]];
        [self addAttribute:[JMXAttribute attributeWithName:@"active" stringValue:@"NO"]];
        activeIn = [self registerInputPin:@"active" withType:kJMXBooleanPin andSelector:@"setActivePin:"  allowedValues:nil initialValue:[NSNumber numberWithBool:NO]];
        activeOut = [self registerOutputPin:@"active" withType:kJMXBooleanPin];
        [self registerInputPin:@"name" withType:kJMXStringPin andSelector:@"setEntityName:"];
        [[JMXContext sharedContext] addEntity:self];
        [self performSelectorOnMainThread:@selector(notifyCreation) withObject:nil waitUntilDone:NO];
        privateData = [[[NSMutableDictionary alloc] init] retain];
        //NSLog(@"Class: %@ initialized", [self class]);
        self.active = YES;
    }
    return self;
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
    [self unregisterAllPins];
    // TODO - append operations to a queue and run them all at once
    // on the main thread
    @synchronized(self) {
        for (NSXMLNode *node in [self children]) {
            [node detach];
        }
        // as explained above ... we need to wait until done
        [self performSelectorOnMainThread:@selector(notifyRelease) withObject:nil waitUntilDone:YES];
    }

    @synchronized(privateData) {
        [privateData release];
        privateData = nil;
    }
    NSLog(@"Released %@", self);
    [super dealloc];
}

- (void)defaultInputCallback:(id)inputData
{
    
}

- (JMXInputPin *)registerInputPin:(NSString *)pinLabel 
                         withType:(JMXPinType)pinType
{
    return [self registerInputPin:pinLabel withType:pinType andSelector:@"defaultInputCallback:"];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
{
    return [self registerInputPin:pinLabel
                         withType:pinType
                      andSelector:selector
                    allowedValues:nil
                     initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
{
    return [self registerInputPin:pinLabel
                         withType:pinType
                      andSelector:selector
                         userData:userData
                    allowedValues:nil 
                     initialValue:nil];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinLabel 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    return [self registerInputPin:pinLabel
                         withType:pinType
                      andSelector:selector
                         userData:nil
                    allowedValues:pinValues
                     initialValue:value];
}

- (JMXInputPin *)registerInputPin:(NSString *)pinLabel 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value
{
    
    JMXInputPin *newPin = [JMXPin pinWithLabel:pinLabel
                                      andType:pinType
                                 forDirection:kJMXInputPin
                                      ownedBy:self
                                   withSignal:selector
                                     userData:userData
                                allowedValues:pinValues
                                 initialValue:(id)value];
    if (newPin)
        [self registerInputPin:newPin];
    return newPin;
}

- (void)registerInputPin:(JMXInputPin *)aPin
{
    @synchronized(self) {
        [self addChild:aPin];
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:aPin waitUntilDone:NO];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel withType:(JMXPinType)pinType
{
    return [self registerOutputPin:pinLabel withType:pinType andSelector:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
{
    return [self registerOutputPin:pinLabel
                          withType:pinType
                       andSelector:selector
                     allowedValues:nil
                      initialValue:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
{
    return [self registerOutputPin:pinLabel
                          withType:pinType
                       andSelector:selector
                          userData:userData
                     allowedValues:nil
                      initialValue:nil];
}

- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    return [self registerOutputPin:pinLabel
                          withType:pinType
                       andSelector:selector
                          userData:nil
                     allowedValues:pinValues
                      initialValue:value];
}


- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value
{
    JMXOutputPin *newPin = [JMXPin pinWithLabel:pinLabel
                                       andType:pinType
                                  forDirection:kJMXOutputPin
                                       ownedBy:self
                                    withSignal:selector
                                      userData:userData
                                 allowedValues:pinValues
                                  initialValue:(id)value];
    if (newPin) {
        [self registerOutputPin:newPin];
    }
    return newPin;
}

- (void)registerOutputPin:(JMXOutputPin *)aPin
{
    @synchronized(self) {
        [self addChild:aPin];
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(notifyPinAdded:) withObject:aPin waitUntilDone:NO];
}

- (void)proxiedPinDestroyed:(NSNotification *)info
{
    JMXPin *pin = [info object];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"JMXPinDestroyed"
                                                  object:pin];
    for (id p in [self children]) {
        if ([p isProxy] && ((JMXProxyPin *)p).realPin == pin) {
            [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:p waitUntilDone:YES];
            [p detach];
            break;
        }
    }
}

- (void)addProxyPin:(JMXProxyPin *)pin
{
    [self notifyPinAdded:(JMXPin *)pin];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(proxiedPinDestroyed:)
                                                 name:@"JMXPinDestroyed"
                                               object:pin.realPin];
}

- (void)proxyInputPin:(JMXInputPin *)pin withLabel:(NSString *)pinLabel
{
    JMXProxyPin *pPin = [JMXProxyPin proxyPin:pin withLabel:pinLabel ? pinLabel : pin.label];
    @synchronized(self) {
        [self addChild:(JMXPin *)pPin]; // XXX - this cast is just to avoid a warning
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(addProxyPin:) withObject:pPin waitUntilDone:NO];
}

- (void)proxyInputPin:(JMXInputPin *)pin
{
    return [self proxyInputPin:pin withLabel:nil];
}

- (void)proxyOutputPin:(JMXOutputPin *)pin withLabel:(NSString *)pinLabel
{
    JMXProxyPin *pPin = [JMXProxyPin proxyPin:pin withLabel:pinLabel ? pinLabel : pin.label];
    @synchronized(self) {
        [self addChild:(JMXPin *)pPin]; // XXX - this cast is just to avoid a warning
    }
    // We need notifications to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
    // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
    [self performSelectorOnMainThread:@selector(addProxyPin:) withObject:pPin waitUntilDone:NO];
}

- (void)proxyOutputPin:(JMXOutputPin *)pin
{
    return [self proxyOutputPin:pin withLabel:nil];
}

// XXX - possible race conditions here (in both inputPins and outputPins)
- (NSArray *)inputPins
{
    /*
    return [[inputPins allKeys]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [obj1 compare:obj2];
            }];
    */
    return [[[self children] objectsAtIndexes:[[self children] indexesOfObjectsPassingTest:
                                               ^(id obj, NSUInteger idx, BOOL *stop)
                                               {
                                                   if ([obj isKindOfClass:[JMXInputPin class]])
                                                   {
                                                       return YES;
                                                   }
                                                   return NO;
                                               }]]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [[obj1 label] compare:[obj2 label]];
            }
            ];
}

- (NSArray *)outputPins
{
    NSArray *children = [self children];
    return [[children objectsAtIndexes:[children indexesOfObjectsPassingTest:
                                               ^(id obj, NSUInteger idx, BOOL *stop)
                                               {
                                                   if ([obj isKindOfClass:[JMXOutputPin class]]) 
                                                   {
                                                       return YES;
                                                   }
                                                   return NO;
                                               }]]
            sortedArrayUsingComparator:^(id obj1, id obj2)
            {
                return [[obj1 label] compare:[obj2 label]];
            }
            ];
}

- (JMXInputPin *)inputPinWithLabel:(NSString *)pinLabel
{
    for (JMXInputPin *pin in [self inputPins]) {
        if ([pin.label isEqualTo:pinLabel])
            return pin;
    }
    return nil;
}

- (JMXOutputPin *)outputPinWithLabel:(NSString *)pinLabel
{
    for (JMXOutputPin *pin in [self outputPins]) {
        if ([pin.label isEqualTo:pinLabel])
            return pin;
    }
    return nil;
}

- (void)unregisterPin:(JMXPin *)pin
{
    [pin disconnectAllPins];
    [pin detach];
    if ([[NSThread currentThread] isMainThread]) {
        [self notifyPinRemoved:pin];
    } else {
        // notifications needs to be delivered on the thread where the GUI runs (otherwise it won't catch the notification)
        // and since the entity will persist the pin we can avoid waiting for the notification to be completely propagated
        [self performSelectorOnMainThread:@selector(notifyPinRemoved:) withObject:pin waitUntilDone:YES];
    }
    // we can now release the pin
}

- (void)unregisterInputPin:(NSString *)pinLabel
{
    JMXInputPin *pin = nil;
    @synchronized(self) {
        for (JMXInputPin *child in [self inputPins]) {
            if (child.direction == kJMXInputPin && [child.label isEqualTo:pinLabel]) {
                pin = [child retain];
                break;
            }
        }
    }
    if (pin) {
        [self unregisterPin:pin];
        [pin release];
    }
}

- (void)outputPinRemoved:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXEntityOutputPinRemoved"
                                                        object:self
                                                      userInfo:userInfo];
}

- (void)unregisterOutputPin:(NSString *)pinLabel
{
    JMXOutputPin *pin = nil;
    @synchronized(self) {
        for (JMXOutputPin *child in [self outputPins]) {
            if ([child.label isEqualTo:pinLabel]) {
                pin = [child retain];
                break;
            }
        }
    }
    if (pin) {
        [self unregisterPin:pin];
        [pin release];
    }
}

- (void)unregisterAllPins
{
    [self disconnectAllPins];
    for (id child in [self children]) {
        if ([child isProxy] && [child respondsToSelector:@selector(realPin)]) {
            NSBlockOperation *unregisterObserver = [NSBlockOperation blockOperationWithBlock:^{
                [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                name:@"JMXPinDestroyed"
                                                              object:((JMXProxyPin *)child).realPin];
            }];
            [unregisterObserver setQueuePriority:NSOperationQueuePriorityVeryHigh];
            [[NSOperationQueue mainQueue] addOperations:[NSArray arrayWithObject:unregisterObserver]
                                      waitUntilFinished:YES];
            JMXPin *pin = (JMXPin *)child;
            [self unregisterPin:pin];
        }
        if ([child isKindOfClass:[JMXPin class]]) {
            JMXPin *pin = (JMXPin *)child;
            [self unregisterPin:pin];
        }
    }
}

- (void)outputDefaultSignals:(uint64_t)timeStamp
{
    JMXOutputPin *activePin = [self outputPinWithLabel:@"active"];    
    [activePin deliverData:[NSNumber numberWithBool:active] fromSender:self];
}

- (BOOL)attachObject:(id)receiver withSelector:(NSString *)selector toOutputPin:(NSString *)pinLabel
{
    JMXOutputPin *pin = [self outputPinWithLabel:pinLabel];
    if (pin) {
        // create a virtual pin to be attached to the receiver
        // not that the pin will automatically released once disconnected
        JMXInputPin *vPin = [JMXInputPin pinWithLabel:@"vpin"
                                             andType:pin.type
                                        forDirection:kJMXInputPin
                                             ownedBy:receiver
                                          withSignal:selector];
        [pin connectToPin:vPin];
        return YES;
    }
    return NO;
}

- (void)disconnectAllPins
{
    for (id child in [self children]) {
        if ([child respondsToSelector:@selector(disconnectAllPins)]) {
            if (![child isKindOfClass:[JMXEntity class]])
                [child performSelector:@selector(disconnectAllPins)];
        }
    }
}

- (NSString *)description
{
    return (!label || [label isEqual:@""])
           ? self.name
           : [NSString stringWithFormat:@"%@:%@", self.name, label];
}

- (void)activate
{
    if (!self.active)
        self.active = YES;
}

- (void)deactivate
{
    if (self.active)
        self.active = NO;
}

- (void)setActivePin:(NSNumber *)value
{
    if ([value isKindOfClass:[NSNumber class]])
        self.active = [value boolValue];
}

- (id)privateDataForKey:(NSString *)key
{
    @synchronized(privateData) {
        if (privateData)
            return [[[privateData objectForKey:key] retain] autorelease];
    }
    return nil;
}

- (void)addPrivateData:(id)data forKey:(NSString *)key
{
    @synchronized(privateData) {
        if (privateData)
            [privateData setObject:data forKey:key];
    }
}

- (void)removePrivateDataForKey:(NSString *)key
{
    @synchronized(privateData) {
        if (privateData)
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

- (NSString *)label
{
    @synchronized(self) {
        return [[label retain] autorelease];
    }
}

- (void)setLabel:(NSString *)newLabel
{
    @synchronized(self) {
        if (label)
            [label release];
        label = [newLabel copy];
        NSXMLNode *attr = [self attributeForName:@"label"];
        [attr setStringValue:label];
    }
}

- (BOOL)active
{
    @synchronized(activeOut) {
        return active;
    }
}

- (void)setActive:(BOOL)value
{
    @synchronized(activeOut) {
        if (active != value) {
            active = value;
            NSXMLNode *attr = [self attributeForName:@"active"];
            [attr setStringValue:active ? @"YES" : @"NO"];
            activeOut.data = [NSNumber numberWithBool:active];
        }
    }
    JMXThreadedEntity *th = [self privateDataForKey:@"threadedEntity"];
    if (th) {
        if (value)
            [th startThread];
        else
            [th stopThread];
    }
    if ([self conformsToProtocol:@protocol(JMXRunLoop)]) {
        if (value)
            [self start];
        else
            [self stop];
    }
}

#pragma mark <JMXPinOwner>

- (id)provideDataToPin:(JMXPin *)aPin
{
    // TODO - use introspection to determine the return type of a message
    //        to generalize using encapsulation in NSNumber/NSData/NSValue
    // XXX - it seems not possible ... further digging is required
    if ([aPin.label isEqualTo:@"active"]) {
        return [NSNumber numberWithBool:self.active];
    } else {
        SEL selector = NSSelectorFromString(aPin.label);
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
    for (JMXPin *pin in inputPins) {
        list->Set(v8::Number::New(cnt++), [pin jsObj]);
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
    for (JMXPin *pin in outputPins) {
        list->Set(v8::Number::New(cnt++), [pin jsObj]);
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
    JMXPin *pin = [entity inputPinWithLabel:[NSString stringWithUTF8String:*value]];
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
    JMXPin *pin = [entity outputPinWithLabel:[NSString stringWithUTF8String:*value]];
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

