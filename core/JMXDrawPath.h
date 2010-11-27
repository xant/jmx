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

#define kJMXDrawPathBufferCount 32

/*!
 * @class JMXDrawPath
 * @abstract Base class for entities
 * @discussion
 * This class wraps CGPath* API (from CoreGraphics) to provide 2D drawing functionalities
 * Drawing is done using an openglcontext to try obtaining best performances
 */ 
@interface JMXDrawPath : NSObject {
@protected
    CGLayerRef pathLayers[kJMXDrawPathBufferCount];
    UInt32 pathLayerOffset;
    CIImage *currentFrame;
@private
    JMXSize *_frameSize;
    BOOL _clear;
}

/*!
 @property currentFrame
 @abstract access the currentFrame
 */
@property (readonly) CIImage *currentFrame;

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
@end
