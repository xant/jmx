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

@class VJXEntity;

@interface VJXPinSignal : NSObject {
    id data;
    id sender;
}

@property (retain) id data;
@property (retain) id sender;

+ signalFrom:(id)sender withData:(id)data;
- (id)initWithSender:(id)theSender andData:(id)theData;

@end
typedef enum {
    kVJXVoidPin,
    kVJXStringPin,
    kVJXNumberPin,
    kVJXImagePin,
    kVJXAudioPin,
    kVJXPointPin,
    kVJXSizePin,
} VJXPinType;

typedef enum {
    kVJXInputPin,
    kVJXOutputPin,
    kVJXAnyPin
} VJXPinDirection;

@interface VJXPin : NSObject <NSCopying> {
@protected
    VJXPinType          type;
    NSString            *name;
    NSMutableDictionary *properties;
    BOOL                multiple; // default NO
    BOOL                continuous; // default YES
    BOOL                retainData; // default YES
    BOOL                buffered; // default NO
    id                  currentData;
    id                  currentSender;
    VJXPinDirection     direction;
    id                  owner;
    id                  minValue;
    id                  maxValue;
    NSString            *ownerSignal;
    NSMutableArray      *allowedValues;
}

@property (readonly)  VJXPinType type;
@property (readonly)  NSString *name;
@property (readonly)  BOOL multiple;
@property (readonly)  VJXPinDirection direction;
@property (readonly)  NSArray *allowedValues;
@property (readwrite) BOOL continuous;
@property (readwrite) BOOL retainData;
@property (readwrite) BOOL buffered;
@property (readonly) id owner;
@property (readonly) id minValue;
@property (readonly) id maxValue;

+ (NSString *)nameforType:(VJXPinType)aType;

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
    allowedValues:(NSArray *)allowedValues;

+ (id)pinWithName:(NSString *)name
          andType:(VJXPinType)pinType
     forDirection:(VJXPinDirection)pinDirection 
          ownedBy:(id)pinOwner 
       withSignal:(NSString *)pinSignal
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
     allowedValues:(NSArray *)pinValues;

- (id)initWithName:(NSString *)pinName
           andType:(VJXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
     allowedValues:(NSArray *)pinValues
      initialValue:(id)value;

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
- (id)readPinValue;
- (void)deliverSignal:(id)data fromSender:(id)sender;
- (void)sendData:(id)data toReceiver:(id)receiver withSelector:(NSString *)selectorName fromSender:(id)sender;
@end
