//
//  JMXMouseEvent.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXEvent.h"

/*
 // Introduced in DOM Level 2:
 interface MouseEvent : UIEvent {
 readonly attribute long             screenX;
 readonly attribute long             screenY;
 readonly attribute long             clientX;
 readonly attribute long             clientY;
 readonly attribute boolean          ctrlKey;
 readonly attribute boolean          shiftKey;
 readonly attribute boolean          altKey;
 readonly attribute boolean          metaKey;
 readonly attribute unsigned short   button;
 readonly attribute EventTarget      relatedTarget;
 void               initMouseEvent(in DOMString typeArg, 
 in boolean canBubbleArg, 
 in boolean cancelableArg, 
 in views::AbstractView viewArg, 
 in long detailArg, 
 in long screenXArg, 
 in long screenYArg, 
 in long clientXArg, 
 in long clientYArg, 
 in boolean ctrlKeyArg, 
 in boolean altKeyArg, 
 in boolean shiftKeyArg, 
 in boolean metaKeyArg, 
 in unsigned short buttonArg, 
 in EventTarget relatedTargetArg);
 };
*/
@interface JMXMouseEvent : JMXEvent
{
    NSInteger screenX;
    NSInteger screenY;
    BOOL      ctrlKey;
    BOOL      shiftKey;
    BOOL      altKey;
    BOOL      metaKey;
    unsigned short button;
    NSXMLNode *relatedTarget;
}

@property (assign) NSInteger screenX;
@property (assign) NSInteger screenY;
@property (assign) BOOL      ctrlKey;
@property (assign) BOOL      shiftKey;
@property (assign) BOOL      altKey;
@property (assign) BOOL      metaKey;
@property (assign) unsigned short button;
@property (assign) NSXMLNode *relatedTarget;

@end
