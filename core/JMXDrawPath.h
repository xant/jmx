//
//  JMXDrawPath.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXSize.h"
#import "JMXPoint.h"

#define kJMXDrawPathBufferCount 32

@interface JMXDrawPath : NSObject {
@protected
    CIImage *currentFrame;
    CGLayerRef pathLayers[kJMXDrawPathBufferCount];
    UInt32 pathLayerOffset;
}

@property (readonly) CIImage *currentFrame;

+ drawPathWithSize:(JMXSize *)frameSize;
- drawRect:(JMXPoint *)origin size:(JMXSize *)size;
- drawCircle:(JMXPoint *)center radius:(NSUInteger)radius;
- drawTriangle:(NSArray *)points;
- drawPoligon:(NSArray *)points;
- lockFocus; // allow to use an NSBezierPath directly
- unlockFocus; // must be called to wrap out direct NSBezierPath drawing

@end
