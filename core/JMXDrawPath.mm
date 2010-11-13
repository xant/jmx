//
//  JMXDrawPath.mm
//  JMX
//
//  Created by xant on 11/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Quartz/Quartz.h>
#import "JMXDrawPath.h"


@implementation JMXDrawPath

+ (id)drawPathWithFrameSize:(JMXSize *)frameSize
{
    return [[[self alloc] initWithFrameSize:frameSize] autorelease];
}

- (id)initWithFrameSize:(JMXSize *)frameSize
{
    self = [super init];
    if (self) {
        // initialize the storage for the spectrum images
        
        
        
        NSOpenGLPixelFormatAttribute    attributes[] = {
            NSOpenGLPFAPixelBuffer,
            NSOpenGLPFANoRecovery,
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADepthSize, 24,
            (NSOpenGLPixelFormatAttribute) 0
        };
        NSOpenGLPixelFormat*            format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
        /*
         //Create the OpenGL pixel buffer to render into
         pixelBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:GL_TEXTURE_RECTANGLE_EXT textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:layerSize.width pixelsHigh:layerSize.height];
         if(pixelBuffer == nil) {
         NSLog(@"Cannot create OpenGL pixel buffer");
         [self release];
         return nil;
         }
         */
        //Create the OpenGL context to render with (with color and depth buffers)
        NSOpenGLContext *openGLContext = [[[NSOpenGLContext alloc] initWithFormat:format shareContext:nil] autorelease];
        if(openGLContext == nil) {
            NSLog(@"Cannot create OpenGL context");
            [self release];
            return nil;
        }
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CIContext * ciContext = [CIContext contextWithCGLContext:(CGLContextObj)[openGLContext CGLContextObj]
                                                     pixelFormat:(CGLPixelFormatObj)[format CGLPixelFormatObj]
                                                      colorSpace:colorSpace
                                                         options:nil];
        CGColorSpaceRelease(colorSpace);
        pathLayerOffset = 0;
        for (int i = 0; i < kJMXDrawPathBufferCount; i++) {
            CGSize layerSize = { frameSize.width, frameSize.height };
            pathLayers[i] = [ciContext createCGLayerWithSize:layerSize info: nil];
        }
        _frameSize = [frameSize copy];
        _clear = NO;
        currentFrame = nil;
    }
    return self;
}

- (void)dealloc
{
    for (int i = 0; i < kJMXDrawPathBufferCount; i++) {
        CGLayerRelease(pathLayers[i]);
    }
    if (_savedContext)
        [self unlockFocus];
    [_frameSize release];
    if (currentFrame)
        [currentFrame release];
    [super dealloc];
}

- (void)clearFrame
{
    if (_clear) {
        UInt32 pathIndex = pathLayerOffset+1%kJMXDrawPathBufferCount;
        NSRect fullFrame = { { 0, 0 }, { _frameSize.width, _frameSize.height } };
        [self lockFocus];
        NSBezierPath *clearPath = [NSBezierPath bezierPathWithRect:fullFrame];
        [[NSColor blackColor] setFill];
        [[NSColor blackColor] setStroke];
        [clearPath fill];
        [clearPath stroke];
        [self unlockFocus];
        _clear = NO;
        pathIndex++;
    }
}

- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    [self lockFocus];
    NSRect frameSize = { { origin.x, origin.y }, { size.width, size.height }};
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:frameSize];
    if (fillColor) {
        [fillColor setFill];
        [path fill];
    }
    [strokeColor setStroke];
    [path stroke];
    [self unlockFocus];
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    [self lockFocus];
    NSRect frameSize = NSMakeRect(center.x, center.y, radius*2, radius*2);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: frameSize];
    if (fillColor) {
        [fillColor setFill];
        [circlePath fill];
    }
    [strokeColor setStroke];
    [circlePath stroke];
    [self unlockFocus];
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
        [self lockFocus];
        NSBezierPath *path = [NSBezierPath bezierPath];
        // TODO - check if the array really contains JMXPoints
        [path moveToPoint:((JMXPoint *)[points objectAtIndex:0]).nsPoint];
        for (int i = 1; i < [points count]; i++) {
            [path lineToPoint:((JMXPoint *)[points objectAtIndex:i]).nsPoint];
        }
        if (fillColor) {
            [fillColor setFill];
            [path fill];
        }
        [strokeColor setStroke];
        [path stroke];
        [self unlockFocus];
    } else {
        // TODO - Error messages
    }
}

- (void)clear
{
    _clear = YES;
}
         
- (void)lockFocus
{
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    
    NSGraphicsContext *pathContext = [NSGraphicsContext
                                       graphicsContextWithGraphicsPort:CGLayerGetContext(pathLayers[pathIndex])
                                       flipped:NO];
    _savedContext = [NSGraphicsContext currentContext];
    [NSGraphicsContext setCurrentContext:pathContext];
}

- (void)unlockFocus
{
    if (_savedContext) {
        [NSGraphicsContext setCurrentContext:_savedContext];
        _savedContext = nil;
    }
}

- (void)render
{
    @synchronized(self) {
        UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
        if (currentFrame)
            [currentFrame release];
        currentFrame = [[CIImage imageWithCGLayer:pathLayers[pathIndex]] retain];
    }
}

- (CIImage *)currentFrame
{
    CIImage *image = nil;
    @synchronized(self) {
        image = [currentFrame retain];
    }
    return [currentFrame autorelease];
}

@end
