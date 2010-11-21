//
//  JMXConnector.h
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

#import <Cocoa/Cocoa.h>
#import "JMXSize.h"
#import "JMXPoint.h"
#import "JMXAudioBuffer.h"
#import "JMXPinSignal.h"
#import "JMXV8.h"

@class JMXEntity;

/*!
 @enum
 kJMXVoidPin, NSVoid
 kJMXStringPin, NSString
 kJMXTextPin, NSString
 kJMXNumberPin, NSNumber
 kJMXImagePin, CIImage
 kJMXAudioPin, JMXAudioBuffer
 kJMXPointPin, JMXPoint
 kJMXSizePin, JMXSize
 kJMXColorPin, NSColor
 
 */
typedef enum {
    kJMXVoidPin,
    kJMXStringPin,
    kJMXTextPin,
    kJMXNumberPin,
    kJMXImagePin,
    kJMXAudioPin,
    kJMXPointPin,
    kJMXSizePin,
    kJMXColorPin,
} JMXPinType;

typedef enum {
    kJMXInputPin,
    kJMXOutputPin,
    kJMXAnyPin
} JMXPinDirection;

#define kJMXPinDataBufferMask 0x03

@interface JMXPin : NSObject <NSCopying, JMXV8> {
@protected
    JMXPinType          type;
    NSString            *name;
    NSMutableDictionary *properties;
    BOOL                multiple; // default NO
    BOOL                continuous; // default YES
    BOOL                sendNotifications; // default YES
    id                  currentSender;
    BOOL                connected;
    id                  dataBuffer[kJMXPinDataBufferMask+1]; // double buffer synchronized for writers
                                       // but lockless for readers
    UInt32              rOffset;
    UInt32              wOffset;
    JMXPinDirection     direction;
    id                  owner; // weak reference (the owner retains us)
    id                  minValue;
    id                  maxValue;
    id                  ownerUserData; // weak reference (depends on the owner)
    NSString            *ownerSignal; // weak reference (depends on the owner)
    NSMutableArray      *allowedValues;
    NSRecursiveLock     *writersLock;
}

@property (readonly)  JMXPinType type;
@property (readonly)  NSString *name;
@property (readonly)  BOOL multiple;
@property (readonly)  JMXPinDirection direction;
@property (readonly)  NSArray *allowedValues;
@property (readwrite) BOOL continuous;
@property (readonly) id owner;
@property (readonly) id minValue;
@property (readonly) id maxValue;
@property (readonly) BOOL connected;
@property (readwrite) BOOL sendNotifications;

+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal;

+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData;


+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues;

+ (id)pinWithName:(NSString *)name
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues
     initialValue:(id)value;

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal;

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData;

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues;

- (id)initWithName:(NSString *)pinName
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value;

+ (NSString *)nameforType:(JMXPinType)type;

- (BOOL)connectToPin:(JMXPin *)destinationPin;
- (void)disconnectFromPin:(JMXPin *)destinationPin;
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
- (void)performSignal:(JMXPinSignal *)signal;
- (BOOL)isCorrectDataType:(id)data;
// allows to access the current pin value stored in 'currentData'
- (id)readData;
// delivers anonymous data (XXX - perhaps we shouldn't allow this)
- (void)deliverData:(id)data;
// signals new data to pin's receivers and stores the value in 'currentData'
- (void)deliverData:(id)data fromSender:(id)sender;
- (BOOL)canConnectToPin:(JMXPin *)pin;

@end

/*
#ifdef __JMXV8__
v8::Handle<v8::Value> JMXPinJSContructor(const Arguments& args);
#endif
*/