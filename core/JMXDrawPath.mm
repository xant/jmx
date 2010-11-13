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


- (id)initWithSize:(JMXSize *)size
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
            CGSize layerSize = { size.width, size.height };
            pathLayers[i] = [ciContext createCGLayerWithSize:layerSize info: nil];
        }
        
    }
    return self;
}

- (CIImage *)currentFrame
{
    return [[currentFrame retain] autorelease];
}

@end
