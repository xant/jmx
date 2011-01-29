//
//  JMXCanvasElement.h
//  JMX
//
//  Created by xant on 1/15/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXElement.h"

@class JMXDrawPath;

@interface JMXCanvasElement : JMXElement {
    double width;
    double height;
    JMXDrawPath *drawPath;
}

@property (assign) double width;
@property (assign) double height;
@property (readonly) JMXDrawPath *drawPath;

@end

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXCanvasElement);

