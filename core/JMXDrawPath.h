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

#define kJMXDrawPathBufferCount 256

@interface JMXDrawPath : NSObject {
@protected
    CGLayerRef pathLayers[kJMXDrawPathBufferCount];
    UInt32 pathLayerOffset;
    CIImage *currentFrame;
@private
    NSGraphicsContext *_savedContext;
    JMXSize *_frameSize;
    BOOL _clear;
}

@property (readonly) CIImage *currentFrame;

+ (id)drawPathWithFrameSize:(JMXSize *)frameSize;
- (id)initWithFrameSize:(JMXSize *)frameSize;
- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
- (void)lockFocus; // allow to use an NSBezierPath directly
- (void)unlockFocus; // must be called to wrap out direct NSBezierPath drawing
- (void)clear;
- (void)render;
@end
