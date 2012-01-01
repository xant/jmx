//
//  JMXDrawPath.h
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXDrawPath.h
 @abstract 2D drawing in JMX
 @discussion Wraps CGPath* API to provide 2D drawing functionalitis
             within the JMX engine
 */

#import <Cocoa/Cocoa.h>
#import "JMXSize.h"
#import "JMXPoint.h"
#import "JMXCanvasStyle.h"
#import "JMXElement.h"
#import "NSFont+V8.h"

#define kJMXDrawPathBufferCount 32

/*!
 * @class JMXDrawPath
 * @abstract Base class for entities
 * @discussion
 * This class wraps CGPath* API (from CoreGraphics) to provide 2D drawing functionalities
 * Drawing is done using an openglcontext to try obtaining best performances
 */ 
@interface JMXDrawPath : JMXElement {
@protected
    CGLayerRef pathLayers[kJMXDrawPathBufferCount];
    UInt32 pathLayerOffset;
    CIImage *currentFrame;
    id<JMXCanvasStyle,JMXV8> fillStyle;
    id<JMXCanvasStyle,JMXV8> strokeStyle;
    NSRecursiveLock *lock; // XXX - remove as soon as we switch to atomic operations
@private
    JMXSize *_frameSize;
    BOOL _clear;
    NSUInteger subPaths;
    double globalAlpha;
    NSString *globalCompositeOperation;
    NSFont *font;
}

/*!
 @property currentFrame
 @abstract access the currentFrame
 */
@property (readonly) CIImage *currentFrame;

@property (readwrite, retain) id<JMXCanvasStyle,JMXV8> fillStyle;

@property (readwrite, retain) id<JMXCanvasStyle,JMXV8> strokeStyle;

@property (readwrite, copy) NSString *globalCompositeOperation;
@property (readwrite, assign) double globalAlpha;
@property (readwrite, retain) NSFont *font;

- (id)jmxInit;

/*!
 @method drawPathWithFrameSize
 @abstract create a new JMXDrawPath instance with the provided frame size
 @param frameSize the size of the frame on which drawing will happen
 @return the newly created instance
 */
+ (id)drawPathWithFrameSize:(JMXSize *)frameSize;
/*!
 @method initWithFrameSize:
 @abstract initialize a new JMXDrawPath instance with the provided frame size
 @param frameSize the size of the frame on which drawing will happen
 @return the initialized instance
 */
- (id)initWithFrameSize:(JMXSize *)frameSize;
/*!
 @method drawRect:size:strokeColor:fillColor
 @abstract draw a rectangle
 @param origin the origin of the rectangle
 @param size the size of the rectangle
 @param strokeColor the color to use.
                    If nil defaults to white
 @param fillColor the color to use for filling the rectangle.
                  If nil no fill will happen 
 */
- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
/*!
 @method drawCircle:radius:strokeColor:fillColor
 @abstract draw a circle
 @param center the center of the circle
 @param radius the radius of the circle
 @param strokeColor the color to use.
 If nil defaults to white
 @param fillColor the color to use for filling the rectangle.
 If nil no fill will happen 
 */
- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
/*!
 @method drawTriangle:strokeColor:fillColor
 @abstract draw a triangle
 @param points an array containing 3 JMXPoint instances (vertexes of the triangle)
 @param strokeColor the color to use.
 If nil defaults to white
 @param fillColor the color to use for filling the rectangle.
 If nil no fill will happen 
 */
- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
/*!
 @method drawPolygon:strokeColor:fillColor
 @abstract draw a polygon
 @param points an array containing an arbitrary number of JMXPoint instances (vertexes of the polygon)
 @param strokeColor the color to use.
 If nil defaults to white
 @param fillColor the color to use for filling the rectangle.
 If nil no fill will happen 
 */
- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor;
/*!
 @method makeCurrentContext
 @abstract make the internal CGContext the current one (allowing direct drawing using CoreGraphics API)
 */

- (void)drawPixel:(JMXPoint *)point strokeColor:(NSColor *)strokeColor;

- (void)makeCurrentContext; // allow to use an NSBezierPath directly
/*!
 @method clear
 @abstract clear the frame (black)
 */
- (void)clear;
/*!
 @method render
 @abstract render the scene on the underlying texture
 */
- (void)render;

- (void)saveCurrentState;

- (void)restorePreviousState;

- (void)clearRect:(JMXPoint *)origin size:(JMXSize *)size;
- (void)fillRect:(JMXPoint *)origin size:(JMXSize *)size;
- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size;

- (void)beginPath;
- (void)closePath;
- (void)moveTo:(JMXPoint *)point;
- (void)lineTo:(JMXPoint *)point;

- (void)quadraticCurveTo:(JMXPoint *)point
            controlPoint:(JMXPoint *)controlPoint;

- (void)bezierCurveTo:(JMXPoint *)point
        controlPoint1:(JMXPoint *)controlPoint1
        controlPoint2:(JMXPoint *)controlPoint2;

- (void)arcTo:(JMXPoint *)point
     endPoint:(JMXPoint *)endPoint
       radius:(CGFloat)radius;

- (void)drawArc:(JMXPoint *)origin
         radius:(CGFloat)radius
     startAngle:(CGFloat)startAngle
       endAngle:(CGFloat)endAngle
  antiClockwise:(BOOL)antiClockwise
    strokeColor:(id<JMXCanvasStyle>)strokeColor
      fillColor:(id<JMXCanvasStyle>)fillColor;

- (void)drawArc:(JMXPoint *)origin
         radius:(CGFloat)radius
     startAngle:(CGFloat)startAngle
       endAngle:(CGFloat)endAngle
  antiClockwise:(BOOL)antiClockwise;

- (void)fill;
- (void)stroke;
- (void)clip;
- (bool)isPointInPath:(JMXPoint *)point;
- (void)strokeText:(NSAttributedString *)text atPoint:(JMXPoint *)point;

@end
