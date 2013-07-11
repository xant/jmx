//
//  JMXEvent.h
//  JMX
//
//  Created by Andrea Guzzo on 1/29/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@class JMXEventListener;

/* Introduced in DOM Level 2:
 interface Event {
 
 // PhaseType
 const unsigned short      CAPTURING_PHASE                = 1;
 const unsigned short      AT_TARGET                      = 2;
 const unsigned short      BUBBLING_PHASE                 = 3;
 
 readonly attribute DOMString        type;
 readonly attribute EventTarget      target;
 readonly attribute EventTarget      currentTarget;
 readonly attribute unsigned short   eventPhase;
 readonly attribute boolean          bubbles;
 readonly attribute boolean          cancelable;
 readonly attribute DOMTimeStamp     timeStamp;
 void               stopPropagation();
 void               preventDefault();
 void               initEvent(in DOMString eventTypeArg, 
 in boolean canBubbleArg, 
 in boolean cancelableArg);
 };
*/

typedef enum {
    kJMXEventPhaseCapturing = 1,
    kJMXEventPhaseAtTarget  = 2,
    kJMXEventPhaseBubbling  = 3,
} JMXEventPhase;

/*!
 @class JMXEvent
 @abstract native class which encapsulates javascript events
 */
@interface JMXEvent : NSObject <JMXV8>
{
    NSString *type;
    NSXMLNode *target;
    NSXMLNode *currentTarget;
    JMXEventPhase eventPhase;
    BOOL bubbles;
    BOOL cancelable;
    NSDate *timeStamp;
    JMXEventListener *listener;
    BOOL capture;
    NSXMLNode *relatedTarget;

}

/*!
 @property type
 @abstract the type of the event
 */
@property (copy) NSString *type;
/*!
 @property target
 @abstract the target of the event
 */
@property (readonly) NSXMLNode *target;
/*!
 @property relatedTarget
 @abstract TODO - document
 */
@property (assign) NSXMLNode *relatedTarget;
/*!
 @property listener
 @abstract the listener of this event
 */
@property (readonly) JMXEventListener *listener;


/*!
 @method eventWithType:target:listener:capture:
 @abstract create a new event of a specific type
 @param type the type of the event
 @param target the target of the event
 @param listener the listener of this event
 @param capture TODO - document
 */
+ (id)eventWithType:(NSString *)type
             target:(NSXMLNode *)target
           listener:(JMXEventListener *)listener
            capture:(BOOL)capture;

/*!
 @method initWithType:target:listener:capture:
 @abstract designated initializer for newly created events
 @param type the type of the event
 @param target the target of the event
 @param listener the listener of this event
 @param capture TODO - document
 */
- (id)initWithType:(NSString *)type
            target:(NSXMLNode *)target
          listener:(JMXEventListener *)listener
           capture:(BOOL)capture;

@end

#ifdef __JMXV8__
JMXV8_DECLARE_CONSTRUCTOR(JMXEvent);
#endif
