//
//  JMXDraw.m
//  VeeJay
//
//  Created by Igor Sutton on 11/9/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXOpenGLDraw.h"

@interface JMXOpenGLDraw ()

- (void)createOpenGLContext;
- (void)prepareOpenGL;

@end


@implementation JMXOpenGLDraw

- (id)init
{
	if ((self = [super init]) != nil) {
		_width = 512;
		_height = 512;
		[self createOpenGLContext];
		[self prepareOpenGL];
	}
	return self;
}

- (void)dealloc
{
	glDeleteFramebuffersEXT(GL_FRAMEBUFFER_EXT, &fboID);
	glDeleteRenderbuffersEXT(GL_RENDERBUFFER_EXT, &rbID);
	glDeleteTextures(GL_TEXTURE_2D, &textureID);
	
	[super dealloc];
}

- (void)createOpenGLContext
{
	NSOpenGLPixelFormatAttribute attribs[] = {
		NSOpenGLPFADoubleBuffer,
		0
	};
	
	_pixelFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	_context = [[NSOpenGLContext alloc] initWithFormat:_pixelFormat shareContext:nil];
}

- (void)prepareOpenGL
{
	[_context makeCurrentContext];
	
	glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
	glMatrixMode(GL_PROJECTION);
	glLoadIdentity();
	glOrtho(-1, 1, -1, 1, -1, 100);
	glDisable(GL_DITHER);
	glDisable(GL_ALPHA_TEST);
	glDisable(GL_BLEND);
	glDisable(GL_STENCIL_TEST);
	glDisable(GL_FOG);
	glDisable(GL_DEPTH_TEST);
	glPixelZoom(1.0, 1.0);
	
	glClearColor(1.0, 1.0, 1.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
	
	// Create objects and bind framebuffer.
	glGenFramebuffersEXT(1, &fboID);
	glGenRenderbuffersEXT(1, &rbID);
	glGenTextures(1, &textureID);
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
	
	// Initialize texture
	glBindTexture(GL_TEXTURE_2D, textureID);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, _width, _height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	
	// Set texture parameters.
	
	// Attach texture to framebuffer color buffer.
	glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, textureID, 0);
	
	// Initialize depth renderbuffer.
	glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, rbID);
	glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, _width, _height);
	
	// Attach framebuffer to depth renderbuffer.
	glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, rbID);
	
}

- (void)drawSomething
{
	[_context makeCurrentContext];
	
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, fboID);
	glPushAttrib(GL_VIEWPORT_BIT);
	glViewport(0, 0, _width, _height);
	
	glClearColor(1, 1, 1, 1);
	glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
	
	glPopAttrib();
	glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
	
	glFlush();
	[_context flushBuffer];
}

- (void)saveImage
{
	[_context makeCurrentContext];
	
	glBindTexture(GL_TEXTURE_2D, textureID);
	
	NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL
																	   pixelsWide:_width
																	   pixelsHigh:_height
																	bitsPerSample:8
																  samplesPerPixel:3
																		 hasAlpha:NO
																		 isPlanar:NO
																   colorSpaceName:NSDeviceRGBColorSpace
																	  bytesPerRow:0
																	 bitsPerPixel:0];
	
	glPixelStorei(GL_UNPACK_ALIGNMENT, 1);

	unsigned char *bitmapData = [bitmap bitmapData];
	
	glReadPixels(0, 0, 64, 64, GL_RGB, GL_UNSIGNED_BYTE, bitmapData);
	

	glBindTexture(GL_TEXTURE_2D, 0);
	
	NSData *data = [bitmap representationUsingType:NSJPEGFileType properties:[NSDictionary dictionary]];
	
	[data writeToFile:@"/tmp/test.jpeg" atomically:YES];
}

@end
