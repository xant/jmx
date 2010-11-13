//
//  JMXOpenGLDraw.h
//  VeeJay
//
//  Created by Igor Sutton on 11/9/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>

@class NSOpenGLContext;

@interface JMXOpenGLDraw : NSObject {
	NSOpenGLContext *_context;
	NSOpenGLPixelFormat *_pixelFormat;
@private
	GLuint fboID;
	GLuint rbID;
	GLuint textureID;
	NSUInteger _width;
	NSUInteger _height;
}

- (void)drawSomething;
- (void)saveImage;

@end
