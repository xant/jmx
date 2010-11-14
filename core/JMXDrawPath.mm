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
            NSOpenGLPFAAccelerated,
            NSOpenGLPFADoubleBuffer,
            NSOpenGLPFADepthSize, 32,
            (NSOpenGLPixelFormatAttribute) 0
        };
        NSOpenGLPixelFormat *format = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attributes] autorelease];
        /*
         //Create the OpenGL pixel buffer to render into
         pixelBuffer = [[NSOpenGLPixelBuffer alloc] initWithTextureTarget:GL_TEXTURE_RECTANGLE_EXT textureInternalFormat:GL_RGBA textureMaxMipMapLevel:0 pixelsWide:layerSize.width pixelsHigh:layerSize.height];
         if(pixelBuffer == nil) {
         NSLog(@"Cannot create OpenGL pixel buffer");
         [self release];
         return nil;
         }
         */
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
            CIContext * ciContext = [CIContext contextWithCGLContext:(CGLContextObj)[openGLContext CGLContextObj]
                                                         pixelFormat:(CGLPixelFormatObj)[format CGLPixelFormatObj]
                                                          colorSpace:colorSpace
                                                             options:nil];
            CGColorSpaceRelease(colorSpace);
            
            CGSize layerSize = { frameSize.width, frameSize.height };
            /*  XXX - this is slower
            CGContextRef cgContext = (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
            pathLayers[i] = CGLayerCreateWithContext(cgContext, layerSize, nil);
            */
            pathLayers[i] = [ciContext createCGLayerWithSize:layerSize info: nil];
            CGContextBeginPath(CGLayerGetContext(pathLayers[i]));
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
    [_frameSize release];
    if (currentFrame)
        [currentFrame release];
    [super dealloc];
}

- (void)clearFrame
{
    if (_clear) {
        UInt32 pathIndex = (pathLayerOffset+1)%kJMXDrawPathBufferCount;
        CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
        CGContextSaveGState(context);
        CGRect fullFrame = { { 0, 0 }, { _frameSize.width, _frameSize.height } };
        CGContextSetRGBFillColor (context, 0.0, 0.0, 0.0, 1.0);
        CGContextFillRect(context, fullFrame);
        _clear = NO;
        pathLayerOffset++;
    }
}

- (void)drawRect:(JMXPoint *)origin size:(JMXSize *)size strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSetRGBStrokeColor (context,
                                [strokeColor redComponent], [strokeColor greenComponent],
                                [strokeColor blueComponent], [strokeColor alphaComponent]
                                );
    if (fillColor) {
        CGContextSetRGBFillColor (context,
                                  [fillColor redComponent], [fillColor greenComponent],
                                  [fillColor blueComponent], [fillColor alphaComponent]
                                  );
        
    }
    CGRect rect = { { origin.x, origin.y }, { size.width, size.height } };
    CGContextStrokeRect(context, rect);
    if (fillColor)
        CGContextFillRect(context, rect);
}

- (void)drawCircle:(JMXPoint *)center radius:(NSUInteger)radius strokeColor:(NSColor *)strokeColor fillColor:(NSColor *)fillColor
{
    [self clearFrame];
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);
    CGContextSetRGBStrokeColor (context,
                                [strokeColor redComponent], [strokeColor greenComponent],
                                [strokeColor blueComponent], [strokeColor alphaComponent]
                                );
    if (fillColor) {
        CGContextSetRGBFillColor (context,
                                  [fillColor redComponent], [fillColor greenComponent],
                                  [fillColor blueComponent], [fillColor alphaComponent]
                                  );
        
    }
    CGRect frameSize = { { center.x, center.y }, { radius*2, radius*2 } };
    CGContextAddEllipseInRect(context, frameSize);
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
        UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
        CGContextRef context = CGLayerGetContext(pathLayers[pathIndex]);

        CGContextSaveGState(context);
        CGContextSetRGBStrokeColor (context,
                                      [strokeColor redComponent], [strokeColor greenComponent],
                                    [strokeColor blueComponent], [strokeColor alphaComponent]
                                      );
        if (fillColor) {
            CGContextSetRGBFillColor (context,
                                        [fillColor redComponent], [fillColor greenComponent],
                                        [fillColor blueComponent], [fillColor alphaComponent]
                                        );
            
        }
        NSPoint origin = ((JMXPoint *)[points objectAtIndex:0]).nsPoint;
        CGContextMoveToPoint(context, origin.x, origin.y);
        for (int i = 1; i < [points count]; i++) {
            origin = ((JMXPoint *)[points objectAtIndex:i]).nsPoint;
            CGContextAddLineToPoint(context, origin.x, origin.y);
        }
        CGContextClosePath(context);
        CGContextRestoreGState(context);
    } else {
        // TODO - Error messages
    }
}

- (void)clear
{
    _clear = YES;
}
         
- (void)makeCurrentContext
{
    UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
    
    NSGraphicsContext *pathContext = [NSGraphicsContext
                                       graphicsContextWithGraphicsPort:CGLayerGetContext(pathLayers[pathIndex])
                                       flipped:NO];
    [NSGraphicsContext setCurrentContext:pathContext];
}

- (void)render
{
    @synchronized(self) {
        UInt32 pathIndex = pathLayerOffset%kJMXDrawPathBufferCount;
        if (currentFrame)
            [currentFrame release];
        CGContextDrawPath(CGLayerGetContext(pathLayers[pathIndex]), kCGPathFillStroke);
        
        currentFrame = [[CIImage imageWithCGLayer:pathLayers[pathIndex]]retain];
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
