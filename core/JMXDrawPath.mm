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
    [super dealloc];
}

- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self lockFocus];
    NSRect frameSize = { { origin.x, origin.y }, { size.width, size.height }};
    NSBezierPath *path = [NSBezierPath bezierPathWithRect:frameSize];
    [strokeColor setFill];
    [fillColor setStroke];
    [path fill];
    [path stroke];
    [self unlockFocus];
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self lockFocus];
    [strokeColor setFill];
    [fillColor setStroke];
    NSRect frameSize = NSMakeRect(10, 10, 10, 10);
    NSBezierPath* circlePath = [NSBezierPath bezierPath];
    [circlePath appendBezierPathWithOvalInRect: frameSize];
    [circlePath fill];
    [circlePath stroke];
    [self unlockFocus];
}

- (void)drawTriangle:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    if ([points count] >= 3) {
        [self drawPoligon:points strokeColor:strokeColor fillColor:fillColor];
    } else {
        // TODO - Error messages
    }
}

- (void)drawPoligon:(NSArray *)points strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    if ([points count]) {
        [self lockFocus];
        [strokeColor setFill];
        [fillColor setStroke];
        NSBezierPath *path = [NSBezierPath bezierPath];
        // TODO - check if the array really contains JMXPoints
        [path moveToPoint:((JMXPoint *)[points objectAtIndex:0]).nsPoint];
        for (int i = 1; i < [points count]; i++) {
            [path lineToPoint:((JMXPoint *)[points objectAtIndex:i]).nsPoint];
        }
        [path fill];
        [path stroke];
        [self unlockFocus];
    } else {
        // TODO - Error messages
    }
}

- (void)clear
{
    NSRect fullFrame = { { 0, 0 }, { _frameSize.width, _frameSize.height } };
    [self lockFocus];
    NSBezierPath *clearPath = [NSBezierPath bezierPathWithRect:fullFrame];
    [[NSColor blackColor] setFill];
    [[NSColor blackColor] setStroke];
    [clearPath fill];
    [clearPath stroke];
    [self unlockFocus];
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

- (CIImage *)currentFrame
{
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CIImage *image = [CIImage imageWithCGLayer:pathLayers[pathIndex]];
    return image;
}

@end
