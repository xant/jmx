//
//  VJXObject.h
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import "VJXInputPin.h"
#import "VJXOutputPin.h"
#ifdef __VJXV8__
#include <v8.h>

#define VJXV8_EXPORT_ENTITY_CLASS(__class) \
    using namespace v8;\
    static std::map<__class *, v8::Persistent<v8::Object> > instancesMap;\
    void __class##JSDestructor(Persistent<Value> object, void *parameter)\
    {\
        NSLog(@"V8 WeakCallback called");\
        __class *obj = static_cast<__class *>(parameter);\
        Local<Context> currentContext  = v8::Context::GetCurrent();\
        VJXJavaScript *ctx = [VJXJavaScript getContext:currentContext];\
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
        __class *instance = [[__class alloc] init];\
        /* make the handle weak, with a callback */\
        jsInstance.MakeWeak(instance, &__class##JSDestructor);\
        instancesMap[instance] = jsInstance;\
        v8::Handle<External> external_ptr = External::New(instance);\
        jsInstance->SetInternalField(0, external_ptr);\
        Local<Context> currentContext  = v8::Context::GetCurrent();\
        VJXJavaScript *ctx = [VJXJavaScript getContext:currentContext];\
        if (ctx) {\
            [ctx addPersistentInstance:jsInstance obj:instance];\
        } else {\
            NSLog(@"Can't find context to attach persistent instance (just leaking)");\
        }\
        return handle_scope.Close(jsInstance);\
    }

#define VJXV8_DECLARE_ENTITY_CONSTRUCTOR(__class)\
    v8::Handle<v8::Value> __class##JSConstructor(const v8::Arguments& args);

#endif
/* this class sends the following notifications
 *
 * VJXEntityWasCreated
 *    object:entity
 * 
 * VJXEntityWasDestroyed
 *    object:entity
 *
 * VJXEntityInputPinAdded
 *    object:entity userInfo:inputPins
 *
 * VJXEntityInputPinRemoved
 *     object:entity userInfo:inputPins
 *
 * VJXEntityOutputPinAdded
 *     object:entity userInfo:outputPins
 *
 * VJXEntityOutputPinRemoved
 *     object:entity userInfo:outputPins
 *
 *
 */


#define kVJXFpsMaxStamps 25

@interface VJXEntity : NSObject <NSCopying> {
@public
    NSString *name;
    BOOL active;
@protected
    NSMutableDictionary *inputPins;
    NSMutableDictionary *outputPins;
@private
}

#pragma mark Properties
@property (readwrite) BOOL active;
@property (readwrite, copy) NSString *name;

#pragma mark Pin API
- (VJXInputPin *)registerInputPin:(NSString *)pinName
                    withType:(VJXPinType)pinType;

- (VJXInputPin *)registerInputPin:(NSString *)pinName
                    withType:(VJXPinType)pinType
                 andSelector:(NSString *)selector;

- (VJXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(VJXPinType)pinType 
                      andSelector:(NSString *)selector
                         userData:(id)userData;

- (VJXInputPin *)registerInputPin:(NSString *)pinName
                         withType:(VJXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

- (VJXInputPin *)registerInputPin:(NSString *)pinName 
                         withType:(VJXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                     withType:(VJXPinType)pinType;

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                     withType:(VJXPinType)pinType
                  andSelector:(NSString *)selector;

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType 
                        andSelector:(NSString *)selector
                           userData:(id)userData;

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

- (VJXOutputPin *)registerOutputPin:(NSString *)pinName
                           withType:(VJXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

- (void)proxyInputPin:(VJXInputPin *)pin;
- (void)proxyOutputPin:(VJXOutputPin *)pin;

- (void)unregisterInputPin:(NSString *)pinName;
- (void)unregisterOutputPin:(NSString *)pinName;

- (void)unregisterAllPins;
- (void)disconnectAllPins;

// autoreleased array of strings (pin names)
- (NSArray *)inputPins;
- (NSArray *)outputPins;

- (VJXInputPin *)inputPinWithName:(NSString *)pinName;
- (VJXOutputPin *)outputPinWithName:(NSString *)pinName;

- (BOOL)attachObject:(id)receiver
        withSelector:(NSString *)selector
        toOutputPin:(NSString *)pinName;

- (void)outputDefaultSignals:(uint64_t)timeStamp;

- (void)activate;
- (void)deactivate;

- (void)notifyModifications;

- (void)proxyInputPin:(VJXInputPin *)pin;
- (void)proxyOutputPin:(VJXOutputPin *)pin;

#pragma mark V8

#ifdef __VJXV8__
+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate;
#endif
@end

