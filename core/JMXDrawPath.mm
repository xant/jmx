//
//  JMXDrawPath.mm
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Quartz/Quartz.h>
#define __JMXV8__
#import "JMXDrawPath.h"
#import "JMXScript.h"
#import "JMXCanvasGradient.h"
#import "JMXCanvasPattern.h"
#import "NSColor+V8.h"
#import "JMXAttribute.h"
#import "JMXImageData.h"

#import <Foundation/Foundation.h>
#include <regex.h>

using namespace v8;

#define JMX_DRAWPATH_WIDTH_DEFAULT 640
#define JMX_DRAWPATH_HEIGHT_DEFAULT 480

#pragma mark JMXDrawPath

@implementation JMXDrawPath

@synthesize fillStyle, strokeStyle, globalAlpha,
            globalCompositeOperation, font, frameSize;

+ (id)drawPathWithFrameSize:(JMXSize *)frameSize
{
    return [[[self alloc] initWithFrameSize:frameSize] autorelease];
}

- (id)init
{
    return [self initWithFrameSize:[JMXSize sizeWithNSSize:NSMakeSize(JMX_DRAWPATH_WIDTH_DEFAULT, JMX_DRAWPATH_HEIGHT_DEFAULT)]];
}

- (id)jmxInit
{
    return [super jmxInit];
}

- (void)clearFrame
{
    if (_clear) {
        [lock lock];
        UInt32 pathIndex = (pathLayerOffset+1)%kJMXDrawPathBufferCount;
        CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
        CGContextSaveGState(context);
        CGRect fullFrame = { { 0, 0 }, { frameSize.width, frameSize.height } };
        CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1.0);
        CGContextFillRect(context, fullFrame);
        CGContextRestoreGState(context);
        _clear = NO;
        pathLayerOffset++;
        [lock unlock];
    }
}

- (id)initWithFrameSize:(JMXSize *)aFrameSize
{
    self = [super init];
    if (self) {
        self.name = @"canvas";
        [self addAttribute:[JMXAttribute attributeWithName:@"class" stringValue:NSStringFromClass([self class])]];
        // initialize the storage for the spectrum images
        NSOpenGLPixelFormatAttribute    attributes[] = {
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 32,
            (NSOpenGLPixelFormatAttribute) 0
        };
        NSOpenGLPixelFormat *format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];

        pathLayerOffset = 0;
        for (int i = 0; i < kJMXDrawPathBufferCount; i++) {
            
            //Create the OpenGL context to render with (with color and depth buffers)
            NSOpenGLContext *openGLContext = [[[NSOpenGLContext alloc] initWithFormat:format shareContext:nil] autorelease];
            if(openGLContext == nil) {
                NSLog(@"Cannot create OpenGL context");
                [self release];
                return nil;
            }
            CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
            CIContext *ciContext = [[CIContext contextWithCGLContext:(CGLContextObj)[openGLContext CGLContextObj]
                                             pixelFormat:(CGLPixelFormatObj)[format CGLPixelFormatObj]
                                              colorSpace:colorSpace
                                                 options:nil] retain];
            CGColorSpaceRelease(colorSpace);
            
            CGSize layerSize = { aFrameSize.width, aFrameSize.height };

            pathLayers[i] = [ciContext createCGLayerWithSize:layerSize info: nil];
            CGContextRef context = CGLayerGetContext(pathLayers[i]);
            CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, aFrameSize.height);
            CGContextConcatCTM(context, flipVertical);
            //CGContextBeginPath(CGLayerGetContext(pathLayers[i]));
        }
        frameSize = [aFrameSize copy];
        _clear = YES;
        currentFrame = nil;
        fillStyle = [(NSColor *)[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0] retain];
        strokeStyle = [(NSColor *)[NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:1.0] retain];
        self.font = [NSFont systemFontOfSize:32];
        lock = [[NSRecursiveLock alloc] init]; // XXX - remove (we don't want locks)
        [self clearFrame];
        _needsRender = YES;
    }
    return self;
}

- (void)dealloc
{
    for (int i = 0; i < kJMXDrawPathBufferCount; i++) {
        CGLayerRelease(pathLayers[i]);
    }
    [frameSize release];
    if (currentFrame)
        [currentFrame release];
    [strokeStyle release];
    [fillStyle release];
    [lock release];
    [super dealloc];
}

- (void)drawArc:(JMXPoint *)origin
         radius:(CGFloat)radius 
     startAngle:(CGFloat)startAngle
       endAngle:(CGFloat)endAngle
  antiClockwise:(BOOL)antiClockwise
{
    [self clearFrame];
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);

    /*  if (!CGContextIsPathEmpty(context)) {
     CGContextAddLineToPoint(context, origin.x, origin.y); // calculate start point properly
     }*/
    CGContextAddArc(context, origin.x, origin.y, radius, startAngle, endAngle, antiClockwise);
    //CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);
    [lock unlock];
    [self render];
}

- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);

    if ([strokeColor isKindOfClass:[NSColor class]]) {
        CGContextSetRGBStrokeColor (context,
                                    [(NSColor *)strokeColor redComponent],
                                    [(NSColor *)strokeColor greenComponent],
                                    [(NSColor *)strokeColor blueComponent],
                                    [(NSColor *)strokeColor alphaComponent]
                                    );
    } else if ([strokeColor isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetStrokePattern(context, [(JMXCanvasPattern *)strokeColor patternRef], [(JMXCanvasPattern *)strokeColor components]);
    }
    
    
    if ([fillColor isKindOfClass:[NSColor class]]) {
        CGContextSetRGBFillColor (context,
                                    [(NSColor *)fillColor redComponent],
                                    [(NSColor *)fillColor greenComponent],
                                    [(NSColor *)fillColor blueComponent],
                                    [(NSColor *)fillColor alphaComponent]
                                    );
    } else if ([fillColor isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetFillPattern(context, [(JMXCanvasPattern *)fillColor patternRef], [(JMXCanvasPattern *)fillColor components]);
    } else if ([fillColor isKindOfClass:[JMXCanvasGradient class]]) {
        JMXCanvasGradient *gradient = (JMXCanvasGradient *)fillColor;
        CGPoint startPoint = CGPointMake(origin.x, origin.y);
        CGPoint endPoint = CGPointMake(origin.x + size.width, origin.y + size.height);
        if (gradient.mode == kJMXCanvasGradientLinear) {
            CGContextDrawLinearGradient(context, [gradient gradientRef], startPoint, endPoint, 0);
        } else if (gradient.mode == kJMXCanvasGradientRadial) {
            startPoint.y += size.height/2;
            endPoint.y -= size.height/2;
            CGFloat radius = size.height/2;
            CGContextDrawRadialGradient(context, [gradient gradientRef], startPoint, radius, endPoint, radius, 0);
        }
    }
    CGRect rect = { { origin.x, origin.y }, { size.width, size.height } };
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);
   /* CGContextStrokeRect(context, rect);
    if (fillColor)
        CGContextFillRect(context, rect);*/
    [lock unlock];
    [self render];
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);
    if ([strokeColor isKindOfClass:[NSColor class]]) {
        CGContextSetRGBStrokeColor (context,
                                    strokeColor.r, strokeColor.g, strokeColor.b, strokeColor.a);
    } else if ([strokeColor isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetStrokePattern(context, [(JMXCanvasPattern *)strokeColor patternRef], [(JMXCanvasPattern *)strokeColor components]);
    }
    
    if ([fillColor isKindOfClass:[NSColor class]]) {
        CGContextSetRGBFillColor (context,
                                  fillColor.r, fillColor.g, fillColor.b, fillColor.a);
    } else if ([fillColor isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetFillPattern(context, [(JMXCanvasPattern *)fillColor patternRef], [(JMXCanvasPattern *)fillColor components]);
    } else if ([fillColor isKindOfClass:[JMXCanvasGradient class]]) {
        JMXCanvasGradient *gradient = (JMXCanvasGradient *)fillColor;
        CGPoint center = CGPointMake(center.x, center.y);
        if (gradient.mode == kJMXCanvasGradientLinear) {
            CGPoint startPoint = CGPointMake(center.x - radius, center.y);
            CGPoint endPoint = CGPointMake(center.x + radius, center.y);
            CGContextDrawLinearGradient(context, [gradient gradientRef], startPoint, endPoint, 0);
        } else if (gradient.mode == kJMXCanvasGradientRadial) {
            CGContextDrawRadialGradient(context, [gradient gradientRef], center, 0, center, radius, 0);
        }
    }
    
    CGRect size = { { center.x, center.y }, { radius*2, radius*2 } };
    CGContextAddEllipseInRect(context, size);
    CGContextDrawPath(context, kCGPathFillStroke);
    CGContextRestoreGState(context);
    [lock unlock];
    [self render];
}

- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    if ([points count] >= 3) {
        [self drawPolygon:points strokeColor:strokeColor fillColor:fillColor];
    } else {
        // TODO - Error messages
    }
}

- (void)drawPolygon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    if ([points count]) {
        [lock lock];
        UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
        CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
        CGContextSaveGState(context);
        if ([strokeColor isKindOfClass:[NSColor class]]) {
            CGContextSetRGBStrokeColor (context,
                                        strokeColor.r, strokeColor.g, strokeColor.b, strokeColor.a);
        } else if ([strokeColor isKindOfClass:[JMXCanvasPattern class]]) {
            CGContextSetStrokePattern(context, [(JMXCanvasPattern *)strokeColor patternRef], [(JMXCanvasPattern *)strokeColor components]);
        }
        
        NSPoint origin = ((JMXPoint *)[points objectAtIndex:0]).nsPoint;
        CGContextMoveToPoint(context, origin.x, origin.y);
        for (int i = 1; i < [points count]; i++) {
            origin = ((JMXPoint *)[points objectAtIndex:i]).nsPoint;
            CGContextAddLineToPoint(context, origin.x, origin.y);
        }
        CGContextClosePath(context);
        if ([fillColor isKindOfClass:[NSColor class]]) {
            CGContextSetRGBFillColor (context,
                                      fillColor.r, fillColor.g, fillColor.b, fillColor.a);
        } else if ([fillColor isKindOfClass:[JMXCanvasPattern class]]) {
            CGContextSetFillPattern(context, [(JMXCanvasPattern *)fillColor patternRef], [(JMXCanvasPattern *)fillColor components]);
        } else if ([fillColor isKindOfClass:[JMXCanvasGradient class]]) {
            JMXCanvasGradient *gradient = (JMXCanvasGradient *)fillColor;
            CGRect boundingBox = CGContextGetPathBoundingBox(context);
            CGPoint startPoint = boundingBox.origin;
            CGPoint endPoint = CGPointMake(startPoint.x + boundingBox.size.width, startPoint.y + boundingBox.size.height);
            if (gradient.mode == kJMXCanvasGradientLinear) {
                CGContextDrawLinearGradient(context, [gradient gradientRef], startPoint, endPoint, 0);
            } else if (gradient.mode == kJMXCanvasGradientRadial) {
                // place start point at the center
                startPoint.x += boundingBox.size.width/2;
                startPoint.y += boundingBox.size.height/2;
                CGFloat radius = MAX(boundingBox.size.width, boundingBox.size.height);
                CGContextDrawRadialGradient(context, [gradient gradientRef], startPoint, 0, startPoint, radius, 0);
            }
        }
        CGContextDrawPath(context, kCGPathFillStroke);
        CGContextRestoreGState(context);
        [lock unlock];
        [self render];
    } else {
        // TODO - Error messages
    }
}

- (void)drawPixel:(JMXPoint *)origin fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);    
    CGContextSetRGBFillColor (context, fillColor.r, fillColor.g,
        fillColor.b, fillColor.a);
    CGRect rect = { { origin.x, origin.y }, { 1, 1 } };
    CGContextFillRect(context, rect);
    CGContextRestoreGState(context);
    [lock unlock];
}

- (void)clear
{
    _clear = YES;
}

- (void)saveCurrentState
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    NSGraphicsContext *pathContext = [NSGraphicsContext
                                      graphicsContextWithGraphicsPort:CGLayerGetContext(pathLayers[pathIndex])
                                      flipped:NO];
    [pathContext saveGraphicsState];
    [lock unlock];
}

- (void)restorePreviousState
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    NSGraphicsContext *pathContext = [NSGraphicsContext
                                      graphicsContextWithGraphicsPort:CGLayerGetContext(pathLayers[pathIndex])
                                      flipped:NO];
    [pathContext restoreGraphicsState];
    [lock unlock];
}

- (void)makeCurrentContext
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    NSGraphicsContext *pathContext = [NSGraphicsContext
                                       graphicsContextWithGraphicsPort:CGLayerGetContext(pathLayers[pathIndex])
                                       flipped:NO];
    [NSGraphicsContext setCurrentContext:pathContext];
    [lock unlock];
}

- (void)scaleX:(CGFloat)x Y:(CGFloat)y
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextScaleCTM(context, x, y);
    [lock unlock];
}

- (void)rotate:(CGFloat)degrees
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextRotateCTM(context, degrees);
    [lock unlock];
}

- (void)translateX:(CGFloat)x Y:(CGFloat)y
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    if (x && y)
        CGContextScaleCTM(context, x, y);
    [lock unlock];
}

- (void)transformA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e F:(CGFloat)f
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    [lock unlock];
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextConcatCTM(context, CGAffineTransformMake(a, b, c, d, e, f));
}

- (void)setTransformA:(CGFloat)a B:(CGFloat)b C:(CGFloat)c D:(CGFloat)d E:(CGFloat)e F:(CGFloat)f
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextConcatCTM(context, CGAffineTransformInvert(CGContextGetCTM(context)));
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, frameSize.height);
    CGContextConcatCTM(context, flipVertical);
    CGContextConcatCTM(context, CGAffineTransformMake(a, b, c, d, e, f));
    [lock unlock];
}

- (void)clearRect:(JMXPoint *)origin size:(JMXSize *)size
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);
    CGRect fullFrame = CGRectMake(origin.nsPoint.x, origin.nsPoint.y,
                                  size.nsSize.width, size.nsSize.height);
    CGContextSetRGBFillColor (context, 1.0, 1.0, 1.0, 1.0);
    CGContextFillRect(context, fullFrame);
    CGContextRestoreGState(context);
    [lock unlock];
}

- (id<JMXCanvasStyle,JMXV8>)fillStyle
{
    id style;
    [lock lock];
    style = [fillStyle retain];
    [lock unlock];
    return [style autorelease];
}

- (void)setFillStyle:(id<JMXCanvasStyle,JMXV8>)aFillStyle
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    if (fillStyle == aFillStyle) {
        [lock unlock];
        return;
    }
    [fillStyle release];
    fillStyle = [aFillStyle retain];
    if ([fillStyle isKindOfClass:[NSColor class]]) {
        CGContextSetRGBFillColor (context,
                                    [(NSColor *)fillStyle redComponent],
                                    [(NSColor *)fillStyle greenComponent],
                                    [(NSColor *)fillStyle blueComponent],
                                    [(NSColor *)fillStyle alphaComponent]);
    } else if ([fillStyle isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetFillPattern(context, [(JMXCanvasPattern *)fillStyle patternRef], [(JMXCanvasPattern *)fillStyle components]);
    }/* else if ([fillColor isKindOfClass:[JMXCanvasGradient class]]) {
      JMXCanvasGradient *gradient = (JMXCanvasGradient *)fillColor;
      if (gradient.mode = kJMXCanvasGradientLinear) {
      CGContextDrawLinearGradient(context, [(JMXCanvasGradient *)strokeColor gradientRef], <#CGPoint startPoint#>, <#CGPoint endPoint#>, <#CGGradientDrawingOptions options#>)
      } else if (gradient.mode = kJMXCanvasGradientRadial) {
      }
    }*/
    [lock unlock];
}

- (id<JMXCanvasStyle,JMXV8>)strokeStyle
{
    id style;
    [lock lock];
    style = [strokeStyle retain];
    [lock unlock];
    return [style autorelease];
}

- (void)setStrokeStyle:(id<JMXCanvasStyle,JMXV8>)aStrokeStyle
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    if (strokeStyle == aStrokeStyle) {
        [lock unlock];
        return;
    }
    [strokeStyle release];
    strokeStyle = [aStrokeStyle retain];
    if ([strokeStyle isKindOfClass:[NSColor class]]) {
        CGContextSetRGBStrokeColor (context,
                                    [(NSColor *)strokeStyle redComponent],
                                    [(NSColor *)strokeStyle greenComponent],
                                    [(NSColor *)strokeStyle blueComponent],
                                    [(NSColor *)strokeStyle alphaComponent]);
    }  else if ([strokeStyle isKindOfClass:[JMXCanvasPattern class]]) {
        CGContextSetFillPattern(context, [(JMXCanvasPattern *)strokeStyle patternRef], [(JMXCanvasPattern *)strokeStyle components]);
    }/* else if ([fillColor isKindOfClass:[JMXCanvasGradient class]]) {
      JMXCanvasGradient *gradient = (JMXCanvasGradient *)fillColor;
      if (gradient.mode = kJMXCanvasGradientLinear) {
      CGContextDrawLinearGradient(context, [(JMXCanvasGradient *)strokeColor gradientRef], <#CGPoint startPoint#>, <#CGPoint endPoint#>, <#CGGradientDrawingOptions options#>)
      } else if (gradient.mode = kJMXCanvasGradientRadial) {
      }
    }*/
    [lock unlock];
}

- (void)fillRect:(JMXPoint *)origin size:(JMXSize *)size
{
    CGRect fullFrame = CGRectMake(origin.nsPoint.x, origin.nsPoint.y,
                                  size.nsSize.width, size.nsSize.height);
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);

    CGContextFillRect(context, fullFrame);
    [lock unlock];
}

- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGRect rect = CGRectMake(origin.nsPoint.x, origin.nsPoint.y,
                                  size.nsSize.width, size.nsSize.height);
    CGContextAddRect(CGLayerGetContext(pathLayers[pathIndex]), rect);
    [lock unlock];
}

- (void)beginPath
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    //CGContextSaveGState(CGLayerGetContext(pathLayers[pathIndex]));
    CGContextBeginPath(CGLayerGetContext(pathLayers[pathIndex]));
    subPaths++;
    _didFill = NO;
    _didStroke = NO;
    [lock unlock];
}

- (void)closePath
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextClosePath(CGLayerGetContext(pathLayers[pathIndex]));
    //CGContextRestoreGState(CGLayerGetContext(pathLayers[pathIndex]));
    subPaths--;
    [lock unlock];
}

- (void)moveTo:(JMXPoint *)point
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    //NSLog(@"Moving to point: %@", point);
    CGContextMoveToPoint(CGLayerGetContext(pathLayers[pathIndex]), point.x, point.y);
    [lock unlock];
}

- (void)lineTo:(JMXPoint *)point
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    //NSLog(@"Line to point: %@", point);

    //CGContextSaveGState(context);
    //CGContextSetLineWidth(context, 1);
    CGContextAddLineToPoint(CGLayerGetContext(pathLayers[pathIndex]), point.x, point.y);
    //CGContextRestoreGState(context);

    [lock unlock];
}

- (void)quadraticCurveTo:(JMXPoint *)point controlPoint:(JMXPoint *)controlPoint
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextAddQuadCurveToPoint(CGLayerGetContext(pathLayers[pathIndex]), controlPoint.x, controlPoint.y, point.x, point.y);
    [lock unlock];
}

- (void)bezierCurveTo:(JMXPoint *)point controlPoint1:(JMXPoint *)controlPoint1 controlPoint2:(JMXPoint *)controlPoint2
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextAddCurveToPoint(CGLayerGetContext(pathLayers[pathIndex]), controlPoint1.x, controlPoint1.y, controlPoint2.x, controlPoint2.y, point.x, point.y);
    [lock unlock];
}

- (void)arcTo:(JMXPoint *)point endPoint:(JMXPoint *)endPoint radius:(CGFloat)radius
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextAddArcToPoint(CGLayerGetContext(pathLayers[pathIndex]), point.x, point.y, endPoint.x, endPoint.y, radius);
    [lock unlock];
}

- (void)fill
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);
    CGPathRef path = CGContextCopyPath(context);
    CGContextDrawPath(context, _didStroke ? kCGPathFillStroke : kCGPathFill);
    CGContextAddPath(context, path);
    CGContextRestoreGState(context);
    _didFill = YES;
    [lock unlock];
    [self render];
}

- (void)stroke
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSaveGState(context);
    CGPathRef path = CGContextCopyPath(context);
    CGContextDrawPath(context, _didFill ? kCGPathFillStroke : kCGPathStroke);
    CGContextAddPath(context, path);
    CGContextRestoreGState(context);
    _didStroke = YES;
    [lock unlock];
    [self render];
}

- (void)clip
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextClip(CGLayerGetContext(pathLayers[pathIndex]));
    [lock unlock];
}

- (bool)isPointInPath:(JMXPoint *)point
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    return CGContextPathContainsPoint(CGLayerGetContext(pathLayers[pathIndex]),
                                      CGPointMake(point.x, point.y),
                                      kCGPathFillStroke);
    [lock unlock];
}

- (void)drawImage:(CIImage *)image
{
    [self makeCurrentContext];
    CGRect fullFrame = CGRectMake(0, 0, frameSize.width, frameSize.height);
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    // XXX - I don't know if this is convenient ... perhaps we could require 
    //       passing a CGImage instead of a CIImage. 
    //       But it could also be that the CIImage is already rendered since 
    //       loaded from a file ... and so no extra work will be done by creating
    //       the NSBitameImageRep
    NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc] initWithCIImage:image] autorelease];
    CGContextDrawImage(context, fullFrame, rep.CGImage);
    // XXX - the following code doesn't work
    //CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //CGColorSpaceRelease(colorSpace);
    //CIContext * ciContext = [CIContext contextWithCGContext:context options:[NSDictionary dictionaryWithObject:[NSValue valueWithPointer:colorSpace] forKey:kCIContextOutputColorSpace]];
    //[ciContext drawImage:image inRect:fullFrame fromRect:fullFrame];
    [lock unlock];
    [self render];
}

- (void)drawImageData:(JMXImageData *)imageData
             fromRect:(CGRect)fromRect
               toRect:(CGRect)toRect
{
    CIImage *image = [[CIImage imageWithData:imageData] imageByCroppingToRect:fromRect];
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);

    NSBitmapImageRep* rep = [[[NSBitmapImageRep alloc] initWithCIImage:image] autorelease];
    CGContextDrawImage(context, toRect, rep.CGImage);

    [lock unlock];
    [self render];
}

- (void)strokeText:(NSAttributedString *)text atPoint:(JMXPoint *)point
{
    // NOTE : makeCurrentContext will lock itself ... 
    // but since we are using a recursive lock it's still safe
    // (no deadlock will happen)
    [lock lock];
    [self makeCurrentContext];
    [self saveCurrentState];
    [text drawAtPoint:point.nsPoint]; // draw at offset position
    [self restorePreviousState];
    [lock unlock];
    [self render];
}

/*
- (void)strokeText:(NSAttributedString *)text
{
    [self strokeText:text atPoint:[JMXPoint pointWithNSPoint:NSZeroPoint]];
}
*/

- (void)render
{
    _needsRender = YES;
}

- (void)doRender
{
    [lock lock];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    /*CGContextSaveGState(context);
     if (!subPaths) {
     CGContextDrawPath(context, kCGPathFillStroke);
     CGContextFillPath(context);
     }
     CGContextRestoreGState(context);*/
    if (currentFrame)
        [currentFrame release];
    currentFrame = [[CIImage imageWithCGLayer:pathLayers[pathIndex]] retain];
    [lock unlock];
    _needsRender = NO;
}

- (CIImage *)currentFrame
{
    CIImage *image = nil;
    [lock lock];
    if (_needsRender)
        [self doRender];
    image = [currentFrame retain];
    [lock unlock];
    return [currentFrame autorelease];
}

static NSString *validCompositeOperations[] = { 
    @"source-atop",
    @"source-in",
    @"source-out",
    @"source-over",
    @"destination-atop",
    @"destination-in",
    @"destination-out",
    @"destination-over",
    @"lighter",
    @"copy",
    @"xor",
    @"vendorName-operationName",
    nil
};

- (NSString *)globalCompositeOperation
{
    @synchronized(self) {
        return [[globalCompositeOperation retain] autorelease];
    }
}

- (void)setGlobalCompositeOperation:(NSString *)operation
{
    for (int i = 0; validCompositeOperations[i]; i++) {
        if ([operation caseInsensitiveCompare:validCompositeOperations[i]] == NSOrderedSame) {
            @synchronized(self) {
                globalCompositeOperation = [validCompositeOperations[i] copy];
            }
            break;
        }
    }
    // TODO - Error Messages
}

#pragma mark V8

static v8::Persistent<v8::FunctionTemplate> objectTemplate;

static v8::Handle<Value> Save(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [drawPath saveCurrentState];
    return Undefined();
}

static v8::Handle<Value> Restore(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [drawPath restorePreviousState];
    return Undefined();
}

static v8::Handle<Value> Scale(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1) {
        CGFloat x = args[0]->NumberValue();
        CGFloat y = args[1]->NumberValue();
        [drawPath scaleX:x Y:y];
    }
    return Undefined();
}

static v8::Handle<Value> Rotate(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length()) {
        CGFloat angle = args[0]->NumberValue();
        [drawPath rotate:angle];
    }
    return Undefined();
}

static v8::Handle<Value> Translate(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1) {
        CGFloat x = args[0]->NumberValue();
        CGFloat y = args[1]->NumberValue();
        if (x && y) // don't waste calling our primitive if we now arguments are invalid
            [drawPath translateX:x Y:y];
    }
    return Undefined();
}

static v8::Handle<Value> Transform(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 5) {
        CGFloat a = args[0]->NumberValue();
        CGFloat b = args[1]->NumberValue();
        CGFloat c = args[2]->NumberValue();
        CGFloat d = args[3]->NumberValue();
        CGFloat e = args[4]->NumberValue();
        CGFloat f = args[5]->NumberValue();
        [drawPath transformA:a B:b C:c D:d E:e F:f];
    }
    return Undefined();
}

static v8::Handle<Value> SetTransform(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 5) {
        CGFloat a = args[0]->NumberValue();
        CGFloat b = args[1]->NumberValue();
        CGFloat c = args[2]->NumberValue();
        CGFloat d = args[3]->NumberValue();
        CGFloat e = args[4]->NumberValue();
        CGFloat f = args[5]->NumberValue();
        [drawPath setTransformA:a B:b C:c D:d E:e F:f];
    }
    return Undefined();
}

static v8::Handle<Value> CreateLinearGradient(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    //JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 3) {
        return handleScope.Close(JMXCanvasGradientJSConstructor(args));
    }
    return handleScope.Close(Undefined());
/*    
    CGContextDrawLinearGradient, <#CGGradientRef gradient#>, <#CGPoint startPoint#>, <#CGPoint endPoint#>, <#CGGradientDrawingOptions options#>)
*/
}

static v8::Handle<Value> CreateRadialGradient(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    if (args.Length() > 5) {
        return handleScope.Close(JMXCanvasGradientJSConstructor(args));
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> CreatePattern(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    if (args.Length() > 5) {
        return handleScope.Close(JMXCanvasPatternJSConstructor(args));
    }
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> ClearRect(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 3) {
        [drawPath clearRect:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                       size:[JMXSize sizeWithNSSize:NSMakeSize(args[2]->NumberValue(), args[3]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> FillRect(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 3) {
        [drawPath fillRect:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                       size:[JMXSize sizeWithNSSize:NSMakeSize(args[2]->NumberValue(), args[3]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> StrokeRect(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 3) {
        [drawPath drawRect:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                      size:[JMXSize sizeWithNSSize:NSMakeSize(args[2]->NumberValue(), args[3]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> BeginPath(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    [drawPath beginPath];
    return Undefined();
}

static v8::Handle<Value> ClosePath(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    [drawPath closePath];
    return Undefined();
}

static v8::Handle<Value> MoveTo(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1) {
        [drawPath moveTo:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> LineTo(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 1) {
        [drawPath lineTo:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> QuadraticCurveTo(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 3) {
        [drawPath quadraticCurveTo:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                      controlPoint:[JMXPoint pointWithNSPoint:NSMakePoint(args[2]->NumberValue(), args[3]->NumberValue())]];
    }
    return Undefined();
}

         
static v8::Handle<Value> BezierCurveTo(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 5) {
        [drawPath bezierCurveTo:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                  controlPoint1:[JMXPoint pointWithNSPoint:NSMakePoint(args[2]->NumberValue(), args[3]->NumberValue())]
                  controlPoint2:[JMXPoint pointWithNSPoint:NSMakePoint(args[4]->NumberValue(), args[5]->NumberValue())]];
    }
    return Undefined();
}

static v8::Handle<Value> ArcTo(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 4) {
        [drawPath arcTo:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
               endPoint:[JMXPoint pointWithNSPoint:NSMakePoint(args[2]->NumberValue(), args[3]->NumberValue())]
                 radius:args[4]->NumberValue()];
    }
    return Undefined();
}

static v8::Handle<Value> Arc(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 5) {
        [drawPath drawArc:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]
                   radius:args[2]->NumberValue()
               startAngle:args[3]->NumberValue()
                 endAngle:args[4]->NumberValue()
            antiClockwise:args[5]->BooleanValue()];
    }
    return Undefined();
}

// XXX - 'Rect' is an already existing symbol (defined in MacTypes.h)
static v8::Handle<Value> AddRect(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() > 4) {
        [drawPath drawRect:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())] 
                      size:[JMXSize sizeWithNSSize:NSMakeSize(args[2]->NumberValue(), args[3]->NumberValue())]];

    }
    return Undefined();
}

static v8::Handle<Value> Fill(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    [drawPath fill];
    return Undefined();
}

static v8::Handle<Value> Stroke(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    [drawPath stroke];
    return Undefined();
}

static v8::Handle<Value> Clip(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    [drawPath clip];
    return Undefined();
}

static v8::Handle<Value> IsPointInPath(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    BOOL test = NO;
    if (args.Length() > 1) {
        test = [drawPath isPointInPath:[JMXPoint pointWithNSPoint:NSMakePoint(args[0]->NumberValue(), args[1]->NumberValue())]];
    }
    return handleScope.Close(v8::Boolean::New(test ? true : false));
}

static v8::Handle<Value> DrawFocusRing(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    //JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    BOOL test = NO;
    if (args.Length() > 3) {
        // TODO - Implement
    }
    return handleScope.Close(v8::Boolean::New(test ? true : false));
}

static v8::Handle<Value> DrawImage(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length()) {
        CIImage *image = nil;
        String::Utf8Value str(args[0]->ToString());
        if (args[0]->IsObject()) {
            if (strcmp(*str, "[object Element]") == 0 ||
                strcmp(*str, "[object Image]") == 0)
            {
                v8::Handle<Object> object = args[0]->ToObject();
                v8::Handle<Value> src = object->Get(String::NewSymbol("src"));
                if (!src.IsEmpty()) {
                    String::Utf8Value url(src->ToString());
                    image = [CIImage imageWithContentsOfURL:[NSURL URLWithString:[NSString stringWithUTF8String:*url]]];
                }
            }
        } else if (args[0]->IsString()) {
            NSString *path = [NSString stringWithUTF8String:*str];
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:path];
            if (imageData)
                image = [CIImage imageWithData:imageData];           
        }
        if (image) {
            [drawPath drawImage:image];
            return handleScope.Close(v8::Boolean::New(true));
        }
    }
    return handleScope.Close(v8::Boolean::New(false));
}

static v8::Handle<Value> GetImageData(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CIImage *image = drawPath.currentFrame;
    CGRect rect = [image extent];
    if (image) {
        
        if (args.Length() > 3) {
            rect.origin.x = args[0]->NumberValue();
            rect.origin.y = args[1]->NumberValue();
            rect.size.width = args[2]->NumberValue();
            rect.size.height = args[3]->NumberValue();
        }
        JMXImageData *imageData = [JMXImageData imageDataWithImage:image rect:rect];
        Handle<Object> obj = [imageData jsObj];
        [pool drain];
        return handleScope.Close(obj);
        
    }
    // TODO - exceptions
    [pool drain];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> CreateImageData(const Arguments& args)
{    
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CIImage *image = drawPath.currentFrame;
    if (args.Length() >= 1) {
        String::Utf8Value str(args[0]->ToString());
        CGSize size = CGSizeZero;
        if (args[0]->IsObject() && strcmp(*str, "[object ImageData]") == 0)
        {
            JMXImageData *originalImageData = (JMXImageData *)args[0]->ToObject()->GetPointerFromInternalField(0);
            size.width = originalImageData.width;
            size.height = originalImageData.height;
            
        } else if (args.Length() == 2) {
            size.width = args[0]->NumberValue();
            size.height = args[1]->NumberValue();            
        }
        if (!CGSizeEqualToSize(size, CGSizeZero)) {
            JMXImageData *imageData = [JMXImageData imageWithSize:size];
            Handle<Object> obj = [imageData jsObj];
            return handleScope.Close(obj);
        }
    }
    // TODO - exceptions
    [pool drain];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value> PutImageData(const Arguments& args)
{
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    CIImage *image = drawPath.currentFrame;
    if (args.Length() >= 3 && args[0]->IsObject() &&
        args[1]->IsNumber() && args[1]->IsNumber())
    {
        CGSize imageSize = [image extent].size;
        double dirtyX = 0;
        double dirtyY = 0;
        double dirtyWidth = imageSize.width;
        double dirtyHeight = imageSize.height;
        String::Utf8Value str(args[0]->ToString());
        if (strcmp(*str, "[object ImageData]") == 0)
        {
            double dX = args[1]->ToNumber()->NumberValue();
            double dY = args[2]->ToNumber()->NumberValue();
             JMXImageData *originalImageData = (JMXImageData *)args[0]->ToObject()->GetPointerFromInternalField(0);  
            if (args.Length() > 3) {
                if (args.Length() >= 4) {
                    dirtyX = args[3]->ToNumber()->NumberValue();
                }
                if (args.Length() >= 5) {
                    dirtyY = args[4]->ToNumber()->NumberValue();
                }
                if (args.Length() >= 6) {
                    dirtyWidth = args[5]->ToNumber()->NumberValue();
                }
                if (args.Length() >= 7) {
                    dirtyHeight = args[6]->ToNumber()->NumberValue();
                }
                
                if (dirtyWidth < 0) {
                    dirtyX += dirtyWidth;
                    dirtyWidth = abs(dirtyWidth);
                }
                if (dirtyX < 0) {
                    dirtyWidth += dirtyX;
                    dirtyX = 0;
                }
                if (dirtyY < 0) {
                    dirtyHeight += dirtyY;
                    dirtyY = 0;
                }
                
                if (dirtyX + dirtyWidth > imageSize.width)
                    dirtyWidth = imageSize.width - dirtyX;

                if (dirtyY + dirtyHeight > imageSize.height)
                    dirtyHeight = imageSize.height - dirtyY;
                
                if (dirtyWidth >= 0 && dirtyHeight >= 0) {
                    CGRect fromRect = CGRectMake(dirtyX, dirtyY, dirtyWidth, dirtyHeight);
                    CGRect toRect = CGRectMake(dX, dY, 
                                               MIN(drawPath.frameSize.width - dX, dirtyWidth),
                                               MIN(drawPath.frameSize.height - dY, dirtyHeight));
                    [drawPath drawImageData:originalImageData fromRect:fromRect toRect:toRect];
                }
            }
            
        }           
    }
    [pool drain];
    return handleScope.Close(Undefined());
}

// void strokeText(in DOMString text, in double x, in double y, in optional double maxWidth);
static v8::Handle<Value> StrokeText(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() >= 3) {
        int maxWidth = 0;
        if (args.Length() > 3) { // maxWidth has been provided
            maxWidth = args[2]->IntegerValue();
            if (maxWidth == 0) // The spec says to stop doing anything if 0 has been passed as maxWidth
                return handleScope.Close(v8::Undefined());
        }

        NSColor *textColor = (NSColor *)[NSColor whiteColor];
        String::Utf8Value text(args[0]->ToString());
        CGFloat x = args[1]->NumberValue();
        CGFloat y = args[2]->NumberValue();
        JMXPoint * strokePoint = [JMXPoint pointWithX:x Y:y];

        
        NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
        [attribs
         setObject:drawPath.font
         forKey:NSFontAttributeName
         ];
        [attribs
         setObject:textColor
         forKey:NSForegroundColorAttributeName
         ];
        NSAttributedString *string = [[[NSAttributedString alloc] initWithString:[NSString stringWithUTF8String:*text] attributes:attribs] autorelease];
        [drawPath strokeText:string atPoint:strokePoint];
    }
    return handleScope.Close(v8::Undefined());
}

static v8::Handle<Value> MeasureText(const Arguments& args)
{
    //v8::Locker lock;
    HandleScope handleScope;
    JMXDrawPath *drawPath = (JMXDrawPath *)args.Holder()->GetPointerFromInternalField(0);
    if (args.Length() >= 1) {
        String::Utf8Value text(args[0]->ToString());
        NSString *textString = [NSString stringWithUTF8String:*text];
        CGSize size = [textString sizeWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:drawPath.font, NSFontAttributeName, nil]];
        JMXSize *textSize = [JMXSize sizeWithNSSize:size];
        return handleScope.Close([textSize jsObj]);
    }
    return handleScope.Close(Undefined());
}

v8::Handle<Value>GetStyle(Local<String> name, const AccessorInfo& info)
{
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    JMXDrawPath *drawPath = (JMXDrawPath *)info.Holder()->GetPointerFromInternalField(0);
    if (strcmp(*nameStr, "fillStyle") == 0) {
        return [[drawPath fillStyle] jsObj];
    } else if (strcmp(*nameStr, "strokeStyle") == 0) {
        return [[drawPath strokeStyle] jsObj];
    }
    return handleScope.Close(Undefined());
}

static void SetStyle(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    NSColor *color = nil;
    JMXDrawPath *drawPath = (JMXDrawPath *)info.Holder()->GetPointerFromInternalField(0);
    String::Utf8Value str(value->ToString());
    if (value->IsObject()) {
        if (strcmp(*str, "[object Color]") == 0) {
            v8::Handle<Object> object = value->ToObject();
            color = (NSColor *)object->GetPointerFromInternalField(0);
        }
    } else {
        color = [NSColor colorFromCSSString:[NSString stringWithUTF8String:*str]];
    }
    if (color) {
        String::Utf8Value nameStr(name);
        if (strcmp(*nameStr, "strokeStyle") == 0) {
            [drawPath setStrokeStyle:color];
        } else if (strcmp(*nameStr, "fillStyle") == 0) {
            [drawPath setFillStyle:color];
        } else {
            // TODO - Error Messages
        }
    }
}

v8::Handle<Value>GetFont(Local<String> name, const AccessorInfo& info)
{
    HandleScope handleScope;
    String::Utf8Value nameStr(name);
    JMXDrawPath *drawPath = (JMXDrawPath *)info.Holder()->GetPointerFromInternalField(0);
    if (drawPath == 0)
        return [drawPath.font jsObj];
    return handleScope.Close(Undefined());
}

static void SetFont(Local<String> name, Local<Value> value, const AccessorInfo& info)
{
    //v8::Locker lock;
    HandleScope handle_scope;
    JMXDrawPath *drawPath = (JMXDrawPath *)info.Holder()->GetPointerFromInternalField(0);
    String::Utf8Value str(value->ToString());
    if (value->IsObject()) {
        if (strcmp(*str, "[object Font]") == 0) {
            v8::Handle<Object> object = value->ToObject();
            NSFont *font = (NSFont *)object->GetPointerFromInternalField(0);
            String::Utf8Value nameStr(name);
            drawPath.font = font;
        }
    } else {
        NSString *fontString = [NSString stringWithUTF8String:*str];
        regex_t exp;
        regmatch_t matches[4];
        
        if (regcomp(&exp, "(\\w+) (\\d+)(px|em|pt)", REG_EXTENDED) == 0) {
            if (regexec(&exp, *str, 4, matches, 0) == 0) {
                /* TODO - take specified font size into account */
            }
        }
        
        NSFont *font = [NSFont fontWithName:fontString size:[NSFont systemFontSize]];
        if (font)
            drawPath.font = font;
        else 
            NSLog(@"Unknown font: %s", *str);
    }
}

- (v8::Handle<v8::Object>)jsObj
{
    //v8::Locker lock;
    HandleScope handle_scope;
    v8::Handle<FunctionTemplate> objectTemplate = [[self class] jsObjectTemplate];
    v8::Handle<Object> jsInstance = objectTemplate->InstanceTemplate()->NewInstance();
    jsInstance->SetPointerInInternalField(0, self);
    return handle_scope.Close(jsInstance);
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("CanvasRenderingContext2D"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("save", FunctionTemplate::New(Save));
    classProto->Set("restore", FunctionTemplate::New(Restore));
    classProto->Set("scale", FunctionTemplate::New(Scale));
    classProto->Set("rotate", FunctionTemplate::New(Rotate));
    classProto->Set("translate", FunctionTemplate::New(Translate));
    classProto->Set("transform", FunctionTemplate::New(Transform));
    classProto->Set("setTransform", FunctionTemplate::New(SetTransform));
    classProto->Set("createLinearGradient", FunctionTemplate::New(CreateLinearGradient));
    classProto->Set("createRadialGradient", FunctionTemplate::New(CreateRadialGradient));
    classProto->Set("createPattern", FunctionTemplate::New(CreatePattern));
    classProto->Set("clearRect", FunctionTemplate::New(ClearRect));
    classProto->Set("fillRect", FunctionTemplate::New(FillRect));
    classProto->Set("strokeRect", FunctionTemplate::New(StrokeRect));
    classProto->Set("beginPath", FunctionTemplate::New(BeginPath));
    classProto->Set("closePath", FunctionTemplate::New(ClosePath));
    classProto->Set("moveTo", FunctionTemplate::New(MoveTo));
    classProto->Set("lineTo", FunctionTemplate::New(LineTo));
    classProto->Set("quadraticCurveTo", FunctionTemplate::New(QuadraticCurveTo));
    classProto->Set("bezierCurveTo", FunctionTemplate::New(BezierCurveTo));
    classProto->Set("arcTo", FunctionTemplate::New(ArcTo));
    classProto->Set("rect", FunctionTemplate::New(AddRect));
    classProto->Set("arc", FunctionTemplate::New(Arc));
    classProto->Set("fill", FunctionTemplate::New(Fill));
    classProto->Set("stroke", FunctionTemplate::New(Stroke));
    classProto->Set("clip", FunctionTemplate::New(Clip));
    classProto->Set("isPointInPath", FunctionTemplate::New(IsPointInPath));
    
    classProto->Set("drawFocusRing", FunctionTemplate::New(DrawFocusRing));
    
    classProto->Set("drawImage", FunctionTemplate::New(DrawImage));
    
    classProto->Set("strokeText", FunctionTemplate::New(StrokeText));
    classProto->Set("measureText", FunctionTemplate::New(MeasureText));
    classProto->Set("fillText", FunctionTemplate::New(StrokeText));
    classProto->Set("getImageData", FunctionTemplate::New(GetImageData));
    classProto->Set("createImageData", FunctionTemplate::New(CreateImageData));
    classProto->Set("putImageData", FunctionTemplate::New(PutImageData));
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("globalAlpha"), GetDoubleProperty, SetDoubleProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("fillStyle"), GetStyle, SetStyle);
    instanceTemplate->SetAccessor(String::NewSymbol("strokeStyle"), GetStyle, SetStyle);
    instanceTemplate->SetAccessor(String::NewSymbol("globalCompositeOperation"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("font"), GetFont, SetFont);
    
    /*
    instanceTemplate->SetAccessor(String::NewSymbol("lineWidth"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("lineCap"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("lineJoin"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("miterLimit"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("shadowOffsetX"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("shadowOffsetY"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("shadowBlur"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("shadowColor"), , );
    
    instanceTemplate->SetAccessor(String::NewSymbol("textAlign"), , );
    instanceTemplate->SetAccessor(String::NewSymbol("textBaseline"), , );
    */
    NSLog(@"CanvasRenderingContext2D objectTemplate created");
    return objectTemplate;
}

@end
