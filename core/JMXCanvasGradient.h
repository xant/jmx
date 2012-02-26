//
//  JMXCanvasGradient.h
//  JMX
//
//  Created by xant on 1/16/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//
/*!
 @header JMXCanvasElement.h
 @abstract HTML5 canvas gradient implementation
 @discussion Implements the HTML5 canvas gradient w3c specification
 */
#import <Cocoa/Cocoa.h>
#import <JMXV8.h>
#import <JMXCanvasStyle.h>

@class JMXPoint;
@class JMXColor;

/*!
 @enum
 @abstract Gradient modes
 @constant kJMXCanvasGradientNone
 @constant kJMXCanvasGradientLinear
 @constant kJMXCanvasGradientRadial
 */
typedef enum {
    kJMXCanvasGradientNone,
    kJMXCanvasGradientLinear,
    kJMXCanvasGradientRadial
} JMXCanvasGradientMode;

/*!
 @class JMXCanvasGradient
 @abstract the objc native class encapsulating a canvas gradient interface (as defined in the w3c spec)
 @discussion this class represent only the a gradient used together with a context2d canvas interface
 */
@interface JMXCanvasGradient : NSObject < JMXV8, JMXCanvasStyle >
{
    CGGradientRef currentGradient;
    NSMutableArray *colors;
    NSMutableArray *locations;
    JMXPoint *srcPoint;
    CGFloat srcRadius;
    JMXPoint *dstPoint;
    CGFloat dstRadius;
    JMXCanvasGradientMode mode;
}

/*!
 @property mode
 @abstract the gradient mode
 */
@property (readonly) JMXCanvasGradientMode mode;

- (id)jmxInit;

/*!
 @method linearGradientFrom:to:
 @abstract create a linear gradient
 @param from
 @param to
 */
+ (id)linearGradientFrom:(JMXPoint *)from to:(JMXPoint *)to;
/*!
 @method radialGradientFrom:radius:to:radius:
 @abstract create a radial gradient
 @param from
 @param r1
 @param to
 @param r2
 */
+ (id)radialGradientFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2;

/*!
 @method initLinearFrom:to:
 */
- (id)initLinearFrom:(JMXPoint *)from to:(JMXPoint *)to;
/*!
 @method initRadialFrom:radius:to:radius:
 */
- (id)initRadialFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2;

/*!
 @method addColor:stop:
 @abstract add a new color at the specified offset
 @param color
 @param offset
 */
- (void)addColor:(NSColor *)color stop:(NSUInteger)offset;

/*!
 @method gradientRef
 @return the underlying CGGradientRef
 */
- (CGGradientRef)gradientRef;

@end

JMXV8_DECLARE_CONSTRUCTOR(JMXCanvasGradient);