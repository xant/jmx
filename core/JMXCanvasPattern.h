//
//  CanvasPattern.h
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
@class JMXRect;

@interface JMXCanvasPattern : NSObject < JMXV8, JMXCanvasStyle >
{
    CGPatternRef currentPattern;
    JMXRect *rect;
    CGImage *image;
    CGPatternTiling tilingMode;
    CGFloat components[4];
}

@property (readonly) JMXRect *rect;
@property (readonly) CGImage *image;

- (id)jmxInit;

+ (id)patternWithBounds:(NSRect)bounds xStep:(NSUInteger)xStep yStep:(NSUInteger)yStep tiling:(CGPatternTiling)tilingMode isColored:(BOOL)isColored;
- (id)initWithBounds:(NSRect)bounds xStep:(NSUInteger)xStep yStep:(NSUInteger)yStep tiling:(CGPatternTiling)tilingMode isColored:(BOOL)isColored;
- (CGPatternRef)patternRef;
- (CGFloat *)components;

@end

JMXV8_DECLARE_CONSTRUCTOR(JMXCanvasPattern);
