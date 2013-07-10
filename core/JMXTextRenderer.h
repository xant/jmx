//
//  JMXTextRenderer.h
//  JMX
//
//  Created by xant on 10/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXTextRenderer.h
 @abstract Renders text on a CVPixelBuffer
 */
#import <Cocoa/Cocoa.h>
#import <OpenGL/CGLContext.h>
#include <QuartzCore/CVPixelBuffer.h>

/*!
 @class JMXTextRenderer
 @abstract Renders text on a CVPixelBuffer
 */
@interface JMXTextRenderer : NSObject {
    CGLContextObj cgl_ctx; // current context at time of texture creation
    GLuint texName;
    NSSize texSize;
    
    NSAttributedString * string;
    NSColor * textColor; // default is opaque white
    NSColor * boxColor; // default transparent or none
    NSColor * borderColor; // default transparent or none
    BOOL staticFrame; // default in NO
    BOOL antialias;	// default to YES
    NSSize marginSize; // offset or frame size, default is 4 width 2 height
    NSSize frameSize; // offset or frame size, default is 4 width 2 height
    float	cRadius; // Corner radius, if 0 just a rectangle. Defaults to 4.0f
    NSImage * image;
    NSBitmapImageRep * bitmap;
    BOOL requiresUpdate;
}

// this API requires a current rendering context and all operations will be performed in regards to thar context
// the same context should be current for all method calls for a particular object instance

// designated initializer
/*!
 @method setAttributedString:
 @param attributedString
 @return the initialized instance
 */
- (void) setAttributedString:(NSAttributedString *)attributedString;

/*!
 @method initWithString:font:textColor:boxColor:borderColor
 @param aString the string
 @param font the font to use
 @param textColor the text color
 @param boxColor the box color
 @param borderColor the border color
 @return the initialized instance
 */
- (void) setString:(NSString *)aString font:(NSFont *)font textColor:(NSColor *)textColor boxColor:(NSColor *)boxColor borderColor:(NSColor *)borderColor;

/*!
 @method textColor
 @return NSColor used to draw the text
 */
- (NSColor *) textColor; // get the pre-multiplied default text color (includes alpha) string attributes could override this
/*!
 @method boxColor
 @return NSColor used to fill the box containing the text
 */
- (NSColor *) boxColor; // get the pre-multiplied box color (includes alpha) alpha of 0.0 means no background box
/*!
 @method borderColor
 @return NSColor used to draw the border of the box containing the text
 */
- (NSColor *) borderColor; // get the pre-multiplied border color (includes alpha) alpha of 0.0 means no border

//- (BOOL) staticFrame; // returns whether or not a static frame will be used

/*!
 @method frameSize
 @return the size of the produced frame
 */
- (NSSize) frameSize; // returns either dynamc frame (text size + margins) or static frame size (switch with staticFrame)
/*!
 @method marginSize
 @return the size of the margins for the text
 */
- (NSSize) marginSize; // current margins for text offset and pads for dynamic frame

// these will force the texture to be regenerated at the next draw
/*!
 @method setMargins:
 @param size set the margins of the text
 */
- (void) setMargins:(NSSize)size; // set offset size and size to fit with offset
/*!
 @method setString:
 @param attributedString
 @abstract set the (attributed) string to be drawn on the frame
 */
- (void) setString:(NSAttributedString *)attributedString; // set string after initial creation
/*!
 @method setString:withAttributes:
 @param aString the new text
 @param attribs attributes to use
 */
- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs; // set string after initial creation
/*!
 @method setTextColor:
 @param color the color used to draw the string
 */
- (void) setTextColor:(NSColor *)color; // set default text color
/*!
 @method setBoxColor:
 @param color the color used to draw the box containing the stirng
 */
- (void) setBoxColor:(NSColor *)color; // set default text color
/*!
 @method setBorderColor:
 @param color the color used to draw the border of the box containing the string
 */
- (void) setBorderColor:(NSColor *)color; // set default text color
/*!
 @method antialias
 @abstract query the instance to determine if antialias will be used
 @return YES if antialias will be used, NO otherwise
 */
- (BOOL) antialias;
/*!
 @method setAntialias
 @abstract set if antialias will be used or not
 param boolean flag to determine if antialias will be used or not
 */
- (void) setAntialias:(bool)request;

/*!
 @method drawOnBuffer:
 @param pixelBuffer the CVPixelBuffer where to render the text
 @return the CVPixelBuffer where text has been rendered
 */
- (CVPixelBufferRef) drawOnBuffer:(CVPixelBufferRef)pixelBuffer;
        
@end
