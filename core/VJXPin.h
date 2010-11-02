//
//  VJXConnector.h
//  VeeJay
//
//  Created by xant on 9/2/10.
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
#import "VJXSize.h"
#import "VJXPoint.h"
#import "VJXAudioBuffer.h"
#import "VJXPinSignal.h"
#ifdef __VJXV8__
#include <v8.h>
#endif

@class VJXEntity;

typedef enum {
    kVJXVoidPin,
    kVJXStringPin,
    kVJXTextPin,
    kVJXNumberPin,
    kVJXImagePin,
    kVJXAudioPin,
    kVJXPointPin,
    kVJXSizePin,
    kVJXColorPin,
} VJXPinType;

typedef enum {
    kVJXInputPin,
    kVJXOutputPin,
    kVJXAnyPin
} VJXPinDirection;

//#define kVJXPinDataBufferCount 2

@interface VJXPin : NSObject <NSCopying> {
@protected
    VJXPinType          type;
    NSString            *name;
    NSMutableDictionary *properties;
    BOOL                multiple; // default NO
    BOOL                continuous; // default YES
    id                  currentSender;
    BOOL                connected;
    id                  dataBuffer[2]; // double buffer synchronized for writers
                                                            // but lockless for readers
    UInt32              rOffset;
    UInt32              wOffset;
    VJXPinDirection     direction;
    id                  owner; // weak reference (the owner retains us)
    id                  minValue;
    id                  maxValue;
    id                  ownerUserData; // weak reference (depends on the owner)
    NSString            *ownerSignal; // weak reference (depends on the owner)
    NSMutableArray      *allowedValues;
    NSRecursiveLock     *writersLock;
}

@property (readonly)  VJXPinType type;
@property (readonly)  NSString *name;
@property (readonly)  BOOL multiple;
@property (readonly)  VJXPinDirection direction;
@property (readonly)  NSArray *allowedValues;
@property (readwrite) BOOL continuous;
@property (readonly) id owner;
@property (readonly) id minValue;
@property (readonly) id maxValue;
@property (readonly) BOOL connected;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData;


+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues
     initialValue:(id)value;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value;

+ (NSString *)nameforType:(VJXPinType)type;

- (BOOL)connectToPin:(VJXPin *)destinationPin;
- (void)disconnectFromPin:(VJXPin *)destinationPin;
- (void)disconnectAllPins;
- (void)allowMultipleConnections:(BOOL)choice;
- (NSString *)typeName;
- (NSString *)description;
- (void)addAllowedValue:(id)value;
- (void)addAllowedValues:(NSArray *)values;
- (void)removeAllowedValue:(id)value;
- (void)removeAllowedValues:(NSArray *)values;
- (void)addMinLimit:(id)minValue;
- (void)addMaxLimit:(id)maxValue;
- (void)performSignal:(VJXPinSignal *)signal;
- (BOOL)isCorrectDataType:(id)data;
// allows to access the current pin value stored in 'currentData'
- (id)readData;
// delivers anonymous data (XXX - perhaps we shouldn't allow this)
- (void)deliverData:(id)data;
// signals new data to pin's receivers and stores the value in 'currentData'
- (void)deliverData:(id)data fromSender:(id)sender;
- (BOOL)canConnectToPin:(VJXPin *)pin;

#pragma mark V8

#ifdef __VJXV8__
+ (v8::Handle<v8::FunctionTemplate>)jsClassTemplate;
- (v8::Handle<v8::Object>)jsObj;
//VJXV8_DECLARE_CONSTRUCTOR(VJXPin);
#endif

@end

#ifdef __VJXV8__
//v8::Handle<v8::Value> VJXPinJSContructor(const Arguments& args);
#endif