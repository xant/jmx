//
//  JMXCanvasGradient.h
//  JMX
//
//  Created by xant on 1/16/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <JMXV8.h>
#import <JMXCanvasStyle.h>

@class JMXPoint;
@class JMXColor;

typedef enum {
    kJMXCanvasGradientNone,
    kJMXCanvasGradientLinear,
    kJMXCanvasGradientRadial
} JMXCanvasGradientMode;

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

@property (readonly) JMXCanvasGradientMode mode;

- (id)jmxInit;

+ (id)linearGradientFrom:(JMXPoint *)from to:(JMXPoint *)to;
+ (id)radialGradientFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2;

- (id)initLinearFrom:(JMXPoint *)from to:(JMXPoint *)to;
- (id)initRadialFrom:(JMXPoint *)from radius:(CGFloat)r1 to:(JMXPoint *)to radius:(CGFloat)r2;

- (void)addColor:(JMXColor *)color stop:(NSUInteger)offset;
- (CGGradientRef)gradientRef;

@end

JMXV8_DECLARE_CONSTRUCTOR(JMXCanvasGradient);