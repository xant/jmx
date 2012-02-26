//
//  JMXCanvasElement.h
//  JMX
//
//  Created by xant on 1/15/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//
/*!
 @header JMXCanvasElement.h
 @abstract HTML5 canvas element implementation
 @discussion Implements the HTML5 canvas element w3c specification
 */
#import <Cocoa/Cocoa.h>
#import "JMXElement.h"

@class JMXDrawPath;

/*!
 @class JMXCanvasElement
 @abstract the xml node representing a canvas element
 @discussion this class represent only the xml container which will hold the actual drawing context
 */
@interface JMXCanvasElement : JMXElement {
    double width;
    double height;
    JMXDrawPath *drawPath;
}

/*!
 @property width
 */
@property (assign) double width;
/*!
 @property height
 */
@property (assign) double height;
/*!
 @property drawPath
 @abstract a reference to the actual drawing context
 */
@property (readonly) JMXDrawPath *drawPath;

@end

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXCanvasElement);

