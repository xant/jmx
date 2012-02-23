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
#import <Foundation/NSXMLElement.h>
#import "JMXInputPin.h"
#import "JMXOutputPin.h"
#import "JMXElement.h"

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
 * This class exposes the follwing input pins:
 * 
 * * active kJMXBooleanPin
 * 
 * * label kJMXStringPin
 *
 * This class exposes the follwing output pins:
 *
 * * active kJMXBooleanPin
 */
@interface JMXEntity : JMXElement <JMXPinOwner> {
@public
    NSString *label;
    BOOL active;
@protected
    /*
    NSMutableDictionary *inputPins;
    NSMutableDictionary *outputPins;*/
    NSXMLElement *inputPins;
    NSXMLElement *outputPins;
    JMXInputPin *activeIn;
    JMXOutputPin *activeOut;
    NSMutableSet *proxyPins;
@private
    NSMutableDictionary *privateData;
    JMXEntity *owner;
}


#pragma mark Properties

/*!
 @property owner
 @abstract the parent node in the DOM hierarchy
 */
@property (readonly) JMXEntity *owner;

/*!
 @property inputPins
 @abstract array containing all input pins for this entity
 */
@property (readonly) NSArray *inputPins;

/*!
 @property outputPins
 @abstract array containing all output pins for this entity
 */
@property (readonly) NSArray *outputPins;

/*!
 @property active
 @abstract determines if the entity is active or not
 */
@property (readwrite) BOOL active;
/*!
 @property label
 @abstract get/set the label of the entity
 */
@property (readwrite, copy) NSString *label;

/*!
 @property description
 @abstract text description of this entity
 */
@property (readonly) NSString *description;

#pragma mark Pin API
/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @return the newly created pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                    withType:(JMXPinType)pinType;

/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @return the newly created pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                    withType:(JMXPinType)pinType
                 andSelector:(NSString *)selector;

/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param userData private data which will be passed to the selector each time it's called
 @return the newly created pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                         withType:(JMXPinType)pinType 
                      andSelector:(NSString *)selector
                         userData:(id)userData;

/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param pinValues array with all possible values for the new pin
 @param value the initial value of the new pin
 @return the newly created pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinLabel
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

/*!
 @method registerInputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param userData private data which will be passed to the selector each time it's called
 @param pinValues array with all possible values for the new pin
 @param value the initial value of the new pin
 @return the newly created pin
 */
- (JMXInputPin *)registerInputPin:(NSString *)pinLabel 
                         withType:(JMXPinType)pinType
                      andSelector:(NSString *)selector
                         userData:(id)userData
                    allowedValues:(NSArray *)pinValues
                     initialValue:(id)value;

- (void)registerInputPin:(JMXInputPin *)aPin;

/*!
 @method registerOutputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @return the newly created pin
 */
- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                     withType:(JMXPinType)pinType;

/*!
 @method registerOutputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @return the newly created pin
 */
- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                     withType:(JMXPinType)pinType
                  andSelector:(NSString *)selector;

/*!
 @method registerOutputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param userData private data which will be passed to the selector each time it's called
 @return the newly created pin
 */
- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType 
                        andSelector:(NSString *)selector
                           userData:(id)userData;

/*!
 @method registerOutputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param userData private data which will be passed to the selector each time it's called
 @param pinValues array with all possible values for the new pin
 @param value the initial value of the new pin
 @return the newly created pin
 */
- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                           userData:(id)userData
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

/*!
 @method registerOutputPin:withType:andSelector:
 @abstract create and register a new input pin
 @param pinLabel the label of the new pin
 @param pinType the datatype transported on this pin
 @param selector the selector to call when new data are signaled on the pin
 @param pinValues array with all possible values for the new pin
 @param value the initial value of the new pin
 @return the newly created pin
 */
- (JMXOutputPin *)registerOutputPin:(NSString *)pinLabel
                           withType:(JMXPinType)pinType
                        andSelector:(NSString *)selector
                      allowedValues:(NSArray *)pinValues
                       initialValue:(id)value;

- (void)registerOutputPin:(JMXOutputPin *)aPin;

/*!
 @method proxyInputPin:withLabel:
 @abstract manage/register an existing input pin as if it is ours
 @param pin the existing pin
 @param pinLabel the new label to assign to the proxied pin
 */
- (void)proxyInputPin:(JMXInputPin *)pin withLabel:(NSString *)pinLabel;

/*!
 @method proxyInputPin:
 @abstract manage/register an existing input pin as if it is ours
 @param pin the existing pin
 */
- (void)proxyInputPin:(JMXInputPin *)pin;

/*!
 @method proxyOutputPin:withLabel:
 @abstract manage/register an existing input pin as if it is ours
 @param pin the existing pin
 @param pinLabel the new label to assign to the proxied pin
 */
- (void)proxyOutputPin:(JMXOutputPin *)pin withLabel:(NSString *)pinLabel;

/*!
 @method proxyOutputPin:
 @abstract manage/register an existing input pin as if it is ours
 @param pin the existing pin
 */
- (void)proxyOutputPin:(JMXOutputPin *)pin;

/* TODO - document */
- (void)unregisterPin:(JMXPin *)pin;

/*!
 @method unregisterInputPin:
 @abstract unregister a managed input pin
 @param pinLabel the pin label
 */
- (void)unregisterInputPin:(NSString *)pinLabel;
/*!
 @method unregisterOutputPin:
 @abstract unregister a managed output pin
 @param pinLabel the pin label
 */
- (void)unregisterOutputPin:(NSString *)pinLabel;

/*!
 @method unregisterAllPins
 @abstract remove all managed pins (both input and output ones). This will also release the not-proxied ones
 */
- (void)unregisterAllPins;

/*!
 @method disconnectAllPins
 @abstract disconnect all pins from their receivers/producers (if any)
 */
- (void)disconnectAllPins;

/*!
 @method inputPins
 @abstract return an autoreleased NSArray containing labels of all managed/registered input pins
 */
// autoreleased array of strings (pin labels)
- (NSArray *)inputPins;
/*!
 @method outputPins
 @abstract return an autoreleased NSArray containing labels of all managed/registered output pins
 */
- (NSArray *)outputPins;

/*!
 @method inputPinWithLabel:
 @abstract return the input pin with the given label (if any is actually registered)
 @return the JMXInputPin object
 */
- (JMXInputPin *)inputPinWithLabel:(NSString *)pinLabel;
/*!
 @method outputPinWithLabel:
 @abstract return the output pin with the given label (if any is actually registered)
 @return the JMXOutputPin object
 */
- (JMXOutputPin *)outputPinWithLabel:(NSString *)pinLabel;

/*!
 @method attachObject:withSelector:toOutputPin:
 @abstract attach any object to an output pin (this allows to debug signals sent on such pin)
 @param receiver the receiver of the pin signal
 @param selector the selector to call when delivering the signal
 @param pinLabel the label of the output pin to hook
 */
- (BOOL)attachObject:(id)receiver
        withSelector:(NSString *)selector
        toOutputPin:(NSString *)pinLabel;

/*!
 @method outputDefaultSignals:
 @abstract force sending the default output signals
 @param timeStamp current timestamp
 */
- (void)outputDefaultSignals:(uint64_t)timeStamp;

/*!
 @method activate
 @abstract activate the entity
 */
- (void)activate;

/*!
 @method deactivate
 @abstract deactivate the entity
 */
- (void)deactivate;

/*!
 @method notifyModifications
 @abstract trigger a notification to let observers know that something has changed
 */
- (void)notifyModifications;

/*!
 @method addPrivateData:forKey:
 @abstract add new private data to this entity. Each entity can be used to store some kind of private data
           in a dictionary using a key which can be used to retrieve the data later. The saved data will be
           available as long as the entity exists. 
 */
- (void)addPrivateData:(id)data forKey:(NSString *)key;
/*!
 @method privateDataForKey:
 @abstract get the privateData saved with the provided key
 */
- (id)privateDataForKey:(NSString *)key;
/*!
 @method removePrivateDataForKey:
 @abstract permanently remove the private data saved with the provided key
 */
- (void)removePrivateDataForKey:(NSString *)key;

@end

#ifdef __JMXV8__
JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXEntity);
#endif
