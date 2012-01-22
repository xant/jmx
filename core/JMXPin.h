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
/*!
 @header JMXPin.h
 @abstract Abstract class for pins. Implements all common functionalities
           (shared among any kind of pin)
 */
#import <Cocoa/Cocoa.h>
#import <Foundation/NSXMLElement.h>
#import "JMXSize.h"
#import "JMXRect.h"
#import "JMXPoint.h"
#import "JMXAudioBuffer.h"
#import "JMXPinSignal.h"
#import "JMXV8.h"
#import "JMXElement.h"

@class JMXPin;

@protocol JMXPinOwner
@required
- (id)provideDataToPin:(JMXPin *)pin;
- (void)receiveData:(id)data fromPin:(JMXPin *)pin;
@end

@class JMXEntity;

/*!
 @enum
 @abstract Datatypes which can be transported through signals
 @constant kJMXVoidPin NSVoid
 @constant kJMXStringPin NSString
 @constant kJMXTextPin NSString
 @constant kJMXCodePin NSString
 @constant kJMXNumberPin NSNumber
 @constant kJMXImagePin CIImage
 @constant kJMXAudioPin JMXAudioBuffer
 @constant kJMXPointPin JMXPoint
 @constant kJMXSizePin JMXSize
 @constant kJMXRectPin JMXRect
 @constant kJMXColorPin NSColor
 @constant kJMXBooleanPin NSNumber
 */
typedef enum {
    kJMXVoidPin = 0,
    kJMXStringPin,
    kJMXTextPin,
    kJMXCodePin,
    kJMXNumberPin,
    kJMXImagePin,
    kJMXAudioPin,
    kJMXPointPin,
    kJMXSizePin,
    kJMXRectPin,
    kJMXColorPin,
    kJMXBooleanPin
} JMXPinType;

/*!
 @enum
 @constant kJMXInputPin Receiver of a signal
 @constant kJMXOutputPin Producer of a signal
 @constant kJMXAnyPin Bi-directional pin which can act as either a receiver or a producer
 */
typedef enum {
    kJMXInputPin,
    kJMXOutputPin,
    kJMXAnyPin
} JMXPinDirection;

/*!
 @define kJMXPinDataBufferMask
 @parseOnly
 */
#define kJMXPinDataBufferMask 0x01 // double buffered
                                   // XXX - if chosing a different mask, note that it must
                                   //       allow only low order bits and withouth 'holes'
                                   //       so for instance 00000111 is a good mask
                                   //       while 00010111 is a wrong mask 

/*!
 @class JMXPin
 @abstract abstract class for any pin type
 @discussion Conforms to procotols: <code>NSCopying</code> <code>JMXV8</code>
 
 You should never use instances of this class directly, but you will use instead
 a concrete subclass (most likely a <code>JMXInputPin</code> or a <code>JMXOutputPin</code>)
 */
@interface JMXPin : JMXElement {
@protected
    JMXPinType          type;
    NSString            *label;
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
    id                  minValue;
    id                  maxValue;
    id                  owner;
    id                  ownerUserData; // weak reference (depends on the owner)
    NSString            *ownerSignal; // weak reference (depends on the owner)
    NSMutableArray      *allowedValues;
    NSRecursiveLock     *dataLock;
    NSXMLElement        *connections;
}

@property (readonly) NSXMLElement *connections;

/*!
 @property type
 @abstract the datatype which can be sent/recived through this pin
 */
@property (readonly)  JMXPinType type;
/*!
 @property label
 @abstract the label of the pin
 */
@property (readonly)  NSString *label;
/*!
 @property multiple
 @abstract boolean flag which determines if the pin accepts multiple connections
 */
@property (readonly)  BOOL multiple;
/*!
 @property direction
 @abstract the direction of the pin
 */
@property (readonly)  JMXPinDirection direction;
/*!
 @property allowedValues
 @abstract NSArray which, if not empty, contains the possible specific values which are accepted by this pin
           anything else will be discarded
 */
@property (readonly)  NSArray *allowedValues;
/*!
 @property continuous
 @abstract boolean flag which determines if the signal will be sent at each tick or only once at connection time
            or if the value changes
 */
@property (readwrite) BOOL continuous;
/*!
 @property owner
 @abstract the owner of the pin. If this is an input pin, the owner is also the default receiver to which signals are propagated
 */
@property (readonly) id owner;
/*!
 @property minValue
 @abstract if not nil, it defines the minimum value for this pin
 @discussion this property will be ignored by pins of type @link kJMXImagePin @/link @link kJMXAudioPin @/link and @link kJMXColorPin @/link datatypes 
 */
@property (readonly) id minValue;
/*!
 @property maxValue
 @abstract if not nil, it defines the maximum value for this pin
 @discussion this property will be ignored by pins of type @link kJMXImagePin @/link @link kJMXAudioPin @/link and @link kJMXColorPin @/link datatypes 
 */
@property (readonly) id maxValue;
/*!
 @property connected
 @abstract boolean flag which will be true if the pin is actually connected, false otherwise
 */
@property (readonly) BOOL connected;
/*!
 @property sendNotification
 @abstract boolean flag which determines if notification for connection/disctionnaction must be posted or not
 @discussion in some scenarios it can be useful to disable notifications (TODO: explain in which scenarios and why)
 */
@property (readwrite) BOOL sendNotifications;
/*!
 @property data
 @abstract the actual data of the pin (so the last delivered signal value)
 */
@property (assign, readwrite) id data; // allow to access data as a property (using the . syntax)

/*!
 @method pinWithLabel:andType:forDirection:ownedBy:withSignal:
 @param pinLabel the label
 @param pinType the type
 @param pinDirection the direction
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @return an new initialized pin already pushed to the active autorelease pool
 */
+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal;

/*!
 @method pinWithLabel:andType:forDirection:ownedBy:withSignal:userData:
 @param pinLabel the label
 @param pinType the type
 @param pinDirection the direction
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @return an new initialized pin already pushed to the active autorelease pool
 */
+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData;

/*!
 @method pinWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinDirection the direction
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @param allowedValues NSArray containing all possible values for this pin
 @return an new initialized pin already pushed to the active autorelease pool
 */
+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues;

/*!
 @method pinWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinDirection the direction
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @param allowedValues NSArray containing all possible values for this pin
 @param value initial value for the new pin
 @return an new initialized pin already pushed to the active autorelease pool
 */
+ (id)pinWithLabel:(NSString *)label
          andType:(JMXPinType)pinType
     forDirection:(JMXPinDirection)pinDirection
          ownedBy:(id)pinOwner
       withSignal:(NSString *)pinSignal
         userData:(id)userData
    allowedValues:(NSArray *)allowedValues
     initialValue:(id)value;

/*!
 @method initWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @return the initialized pin instance
 */
- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal;

/*!
 @method initWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @return the initialized pin instance
 */
- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData;

/*!
 @method initWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @param allowedValues NSArray containing all possible values for this pin
 @return the initialized pin instance
 */
- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)allowedValues;

/*!
 @method initWithLabel:andType:forDirection:ownedBy:withSignal:userData:allowedValues:
 @param pinLabel the label
 @param pinType the type
 @param pinOwner the owner (who will receive data when signaled)
 @param pinSignal the signature of the selector to perform on the owner when a signal arrives
 @param userData user defined data which will be sent to the owner together with the signaled data each time
 @param allowedValues NSArray containing all possible values for this pin
 @param value initial value for the new pin
 @return the initialized pin instance
 */
- (id)initWithLabel:(NSString *)pinLabel
           andType:(JMXPinType)pinType
           ownedBy:(id)pinOwner
        withSignal:(NSString *)pinSignal
          userData:(id)userData
     allowedValues:(NSArray *)allowedValues
      initialValue:(id)value;

/*!
 @method nameforType:
 @abstract returns an NSString with a printable name for a specific datatype
 @param type the @link JMXPinType @/link we want the printable name for
 @return NSString with the printable name
 */
+ (NSString *)nameforType:(JMXPinType)type;
/*!
 @method connectToPin:(JMXPin *)destinationPin
 @param destinationPin the pin we want to make the connection with
 @abstract attempt to make a connection with the provided destinationPin
 @return YES on success, NO otherwise
 */
- (BOOL)connectToPin:(JMXPin *)destinationPin;
/*!
 @method disconnectFromPin:
 @param destinationPin
 @abstract attempt to remove a (possibly) connected pin
 */
- (void)disconnectFromPin:(JMXPin *)destinationPin;
/*!
 @method disconnectAllPins
 @abstract force disconnection of all connected pins
 */
- (void)disconnectAllPins;
/*!
 @method allowMultipleConnections:
 @param choice boolean flag which indicates if we want to allow or disallow multiple connections
 */
- (void)allowMultipleConnections:(BOOL)choice;
/*!
 @method typeName
 @return the printable name of the datatype handled by this pin
 */
- (NSString *)typeName;
/*!
 @method description
 @return a printable description of this pin
 */
- (NSString *)description;
/*!
 @method addAllowedValue:
 @param value an allowed value
 @abstract add a new possible value
 */
- (void)addAllowedValue:(id)value;
/*!
 @method addAllowedValues:
 @param values NSArray containing allowed values
 @abstract add a new possible values
 */
- (void)addAllowedValues:(NSArray *)values;
/*!
 @method removeAllowedValue:
 @param value the value we want to remove
 @abstract remove a specific value if present in the list of allowed ones
 */
- (void)removeAllowedValue:(id)value;
/*!
 @method removeAllowedValue:
 @param values an NSArray of values which must be removed from the list of allowed ones
 @abstract remove any of the provided values which is present in the list of allowed ones
 */
- (void)removeAllowedValues:(NSArray *)values;
/*!
 @method setMinLimit:
 @param minValue
 @abstract set a minimum value
 */
- (void)setMinLimit:(id)minValue;
/*!
 @method setMaxLimit:
 @param maxValue
 @abstract set a maximum value
 */
- (void)setMaxLimit:(id)maxValue;
/*!
 @method performSignal:
 @param signal
 @abstract deliver a signal to all receivers
 */
- (void)performSignal:(JMXPinSignal *)signal;
/*!
 @method isCorrectDataType:
 @param data
 @abstract returns true if the provided data is of the correct datatype for this pin to be received/delivered
 */
- (BOOL)isCorrectDataType:(id)data;
/*!
 @method readData:
 @abstract access the current pin value stored in 'currentData'
 */
- (id)readData;
/*!
 @method deliverData:
 @param data
 @abstract deliver an anonymous signal to all receivers
 @discussion anonymous data means that the 'sender' will be unknown to the receiver
 */
- (void)deliverData:(id)data;
/*!
 @method dekuverData:fromSender:
 @param data
 @param sender
 @abstract signals new data to all receivers and stores the value in 'currentData'
 */
- (void)deliverData:(id)data fromSender:(id)sender;

/*!
 @method cannConnectToPin:
 @param pin the pin we want to test connection to
 @abstract check if connection to a pin can be established (AKA: they are of opposite direction and transport the same datatype)
 @return YES if connection is possible, NO otherwise
 */
- (BOOL)canConnectToPin:(JMXPin *)pin;

@end

/*
#ifdef __JMXV8__
v8::Handle<v8::Value> JMXPinJSContructor(const Arguments& args);
#endif
*/