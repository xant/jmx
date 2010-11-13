//
//  JMXEntity.h
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
/*!
 @header JMXEntity.h
 @abstract Base (abstract) class representing an Entity in the JMX world
 @discussion You usually won't create instances of this class directly
             but you want to access subclasses instead.
             Any entity implementation needs to subclass JMXEntity.
             Basic (and common) functionalities are already implemented in the base
             class so that subclasses should only care about the processing logic.
             In JMX an entity should be considered a processing unit. 
             Its sole aim is to receive data from its input pins and to implement some 
             processing which reflects on the data that will be sent to the output pins
             The only thing that entities know of each other are pins.
             Pins of opposite direction can be connected one to each other 
             (check documentation for <code>JMXPin</code>
 @related JMXPin.h
 */

#import <Cocoa/Cocoa.h>
#import "JMXInputPin.h"
#import "JMXOutputPin.h"
#ifdef __JMXV8__
#include <v8.h>

/*!
 @define JMXV8_EXPORT_ENTITY_CLASS
 @param __class
 */

#define JMXV8_EXPORT_ENTITY_CLASS(__class) \
    using namespace v8;\
    /*static std::map<__class *, v8::Persistent<v8::Object> > instancesMap;*/\
    void __class##JSDestructor(Persistent<Value> object, void *parameter)\
    {\
        NSLog(@"V8 WeakCallback called");\
        __class *obj = static_cast<__class *>(parameter);\
        Local<Context> currentContext  = v8::Context::GetCurrent();\
        JMXScript *ctx = [JMXScript getContext:currentContext];\
        if (ctx) {\
            /* this will destroy the javascript object as well */\
            [ctx removePersistentInstance:obj];\
        } else {\
            NSLog(@"Can't find context to attach persistent instance (just leaking)");\
        }\
    }\
\
    v8::Handle<Value> __class##JSConstructor(const Arguments& args)\
    {\
        HandleScope handle_scope;\
        v8::Handle<FunctionTemplate> classTemplate = [__class jsClassTemplate];\
        Persistent<Object> jsInstance = Persistent<Object>::New(classTemplate->InstanceTemplate()->NewInstance());\
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];\
        __class *instance = [[__class alloc] init];\
        if ([instance respondsToSelector:@selector(jsInit:)]) {\
            NSValue *argsValue = [NSValue valueWithPointer:(void *)&args];\
            [instance performSelector:@selector(jsInit:) withObject:argsValue];\
        }\
        /* make the handle weak, with a callback */\
        jsInstance.MakeWeak(instance, &__class##JSDestructor);\
        /*instancesMap[instance] = jsInstance;*/\
        v8::Handle<External> external_ptr = External::New(instance);\
        jsInstance->SetInternalField(0, external_ptr);\
        Local<Context> currentContext = v8::Context::GetCalling();\
        JMXScript *ctx = [JMXScript getContext:currentContext];\
        if (ctx) {\
            [ctx addPersistentInstance:jsInstance obj:instance];\
        } else {\
            NSLog(@"Can't find context to attach persistent instance (just leaking)");\
        }\
        [pool release];\
        return handle_scope.Close(jsInstance);\
    }

#define JMXV8_DECLARE_ENTITY_CONSTRUCTOR(__class)\
    v8::Handle<v8::Value> __class##JSConstructor(const v8::Arguments& args);

#endif

#define kJMXFpsMaxStamps 25

/*!
 * @class JMXEntity
 * @abstract Base class for entities
 * @discussion
 * This class sends the following notifications
 *
 * JMXEntityWasCreated
 *    object:entity
 * 
 * JMXEntityWasDestroyed
 *    object:entity
 *
 * JMXEntityInputPinAdded
 *    object:entity userInfo:inputPins
 *
 * JMXEntityInputPinRemoved
 *     object:entity userInfo:inputPins
 *
 * JMXEntityOutputPinAdded
 *     object:entity userInfo:outputPins
 *
 * JMXEntityOutputPinRemoved
 *     object:entity userInfo:outputPins
 *
 *
 */

@interface JMXEntity : NSObject <NSCopying> {
@public
    NSString *name;
    BOOL active;
@protected
    NSMutableDictionary *inputPins;
    NSMutableDictionary *outputPins;
@private
}

#pragma mark Properties
/*!
 @property active
 @abstract determines if the entity is active or not
 */
@property (readwrite) BOOL active;
/*!
 @property active
 @abstract get/set the name of the entity
 */
@property (readwrite, copy) NSString *name;

#pragma mark Pin API
/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinName the name of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinName
                    withType:(JMXPinType)pinType;

- (JMXInputPin *)registerInputPin:(NSString *)pinName
                    withType:(JMXPinType)pinType
                 andSelector:(NSString *)selector;

- (JMXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(JMXPinType)pinType 
                      andSelector:(NSString *)selector
                         userData:(id)userData;

- (JMXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

- (JMXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                     withType:(JMXPinType)pinType;

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                     withType:(JMXPinType)pinType
                  andSelector:(NSString *)selector;

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType 
                        andSelector:(NSString *)selector
                           userData:(id)userData;

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

- (JMXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

- (void)proxyInputPin:(JMXInputPin *)pin;
- (void)proxyOutputPin:(JMXOutputPin *)pin;

- (void)unregisterInputPin:(NSString *)pinName;
- (void)unregisterOutputPin:(NSString *)pinName;

- (void)unregisterAllPins;
- (void)disconnectAllPins;

// autoreleased array of strings (pin names)
- (NSArray *)inputPins;
- (NSArray *)outputPins;

- (JMXInputPin *)inputPinWithName:(NSString *)pinName;
- (JMXOutputPin *)outputPinWithName:(NSString *)pinName;

- (BOOL)attachObject:(id)receiver
        withSelector:(NSString *)selector
        toOutputPin:(NSString *)pinName;

- (void)outputDefaultSignals:(uint64_t)timeStamp;

- (void)activate;
- (void)deactivate;

- (void)notifyModifications;

- (void)proxyInputPin:(JMXInputPin *)pin;
- (void)proxyOutputPin:(JMXOutputPin *)pin;

#pragma mark V8
- (void)jsInit:(NSValue *)argsValue;

#ifdef __JMXV8__
+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate;
#endif
@end

