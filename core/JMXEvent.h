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
}

@property (readonly) NSString *type;
@property (readonly) NSXMLNode *target;
@property (readonly) JMXEventListener *listener;

+ (id)eventWithType:(NSString *)type
             target:(NSXMLNode *)target
           listener:(JMXEventListener *)listener
            capture:(BOOL)capture;

- (id)initWithType:(NSString *)type
            target:(NSXMLNode *)target
          listener:(JMXEventListener *)listener
           capture:(BOOL)capture;

@end
