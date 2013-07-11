/*  JMX
 *
 *  (c) Copyright 2010 Andrea Guzzo <xant@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published 
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#import "JMXTextRenderer.h"
/*
@interface NSBezierPath (RoundRect)
+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius;
@end
*/

// The following is a NSBezierPath category to allow
// for rounded corners of the border

#pragma mark -
#pragma mark NSBezierPath Category

/*
@implementation NSBezierPath (RoundRect)

+ (NSBezierPath *)bezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    NSBezierPath *result = [NSBezierPath bezierPath];
    [result appendBezierPathWithRoundedRect:rect cornerRadius:radius];
    return result;
}

- (void)appendBezierPathWithRoundedRect:(NSRect)rect cornerRadius:(float)radius {
    if (!NSIsEmptyRect(rect)) {
		if (radius > 0.0) {
			// Clamp radius to be no larger than half the rect's width or height.
			float clampedRadius = MIN(radius, 0.5 * MIN(rect.size.width, rect.size.height));
			
			NSPoint topLeft = NSMakePoint(NSMinX(rect), NSMaxY(rect));
			NSPoint topRight = NSMakePoint(NSMaxX(rect), NSMaxY(rect));
			NSPoint bottomRight = NSMakePoint(NSMaxX(rect), NSMinY(rect));
			
			[self moveToPoint:NSMakePoint(NSMidX(rect), NSMaxY(rect))];
			[self appendBezierPathWithArcFromPoint:topLeft     toPoint:rect.origin radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:rect.origin toPoint:bottomRight radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:bottomRight toPoint:topRight    radius:clampedRadius];
			[self appendBezierPathWithArcFromPoint:topRight    toPoint:topLeft     radius:clampedRadius];
			[self closePath];
		} else {
			// When radius == 0.0, this degenerates to the simple case of a plain rectangle.
			[self appendBezierPathWithRect:rect];
		}
    }
}

@end

*/
#pragma mark -
#pragma mark JMXTextRenderer

@implementation JMXTextRenderer

#pragma mark -
#pragma mark Deallocs
- (void) dealloc
{
	[textColor release];
	[boxColor release];
	[borderColor release];
	[string release];
	[super dealloc];
}

#pragma mark -
#pragma mark Initializers

- (id)init
{
    self = [super init];
    if (self) {
        staticFrame = NO;
        antialias = YES;
        marginSize.width = 4.0f; // standard margins
        marginSize.height = 2.0f;
        cRadius = 4.0f;
        requiresUpdate = YES;
    }
    return self;
}

#pragma mark -
#pragma mark messages

- (void) setAttributedString:(NSAttributedString *)attributedString
{
    @synchronized(self) {
        if (string)
            [string release];
        string = [attributedString retain];
    }
	// all other variables 0 or NULL
}

- (void) setString:(NSString *)aString font:(NSFont *)font textColor:(NSColor *)theTextColor boxColor:(NSColor *)theBoxColor borderColor:(NSColor *)theBorderColor;
{
    NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
    [attribs
     setObject:font
     forKey:NSFontAttributeName
     ];
    [attribs
     setObject:theTextColor
     forKey:NSForegroundColorAttributeName
     ];
    [attribs
     setObject:theBoxColor
     forKey:NSBackgroundColorAttributeName
     ];
    // XXX - how to use bordercolor now? 
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:aString attributes:attribs];
    [self setAttributedString:attributedString];
    [attributedString release];
}

- (void) setString:(NSString *)aString withAttributes:(NSDictionary *)attribs
{
    NSAttributedString *str = [[NSAttributedString alloc] initWithString:aString attributes:attribs];
    [self setAttributedString:str];
    [str release];
}

- (void) genImage
{
    @synchronized(self) {
        if (image)
            [image release];
        if (bitmap)
            [bitmap release];
        
        
        if ((NO == staticFrame)) { // find frame size if we have not already found it
            frameSize = [string size]; // current string size
            frameSize.width += marginSize.width * 2.0f; // add padding
            frameSize.height += marginSize.height * 2.0f;
        }
        image = [[NSImage alloc] initWithSize:frameSize];
        
        [image lockFocus];
        [[NSGraphicsContext currentContext] setShouldAntialias:antialias];
        if ([boxColor alphaComponent]) { // this should be == 0.0f but need to make sure
            [boxColor set]; 
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height) , 0.5, 0.5)
                                                                 xRadius:cRadius yRadius:cRadius];
            [path fill];
        }
        
        if ([borderColor alphaComponent]) {
            [borderColor set]; 
            NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height), 0.5, 0.5) 
                                                            xRadius:cRadius yRadius:cRadius];
            [path setLineWidth:1.0f];
            [path stroke];
        }
        
        [textColor set]; 
        [string drawAtPoint:NSMakePoint (marginSize.width, marginSize.height)]; // draw at offset position
        bitmap = [[NSBitmapImageRep alloc] initWithFocusedViewRect:NSMakeRect (0.0f, 0.0f, frameSize.width, frameSize.height)];
        [image unlockFocus];
    }
}

#pragma mark Text Color

- (void) setTextColor:(NSColor *)color // set default text color
{
	[color retain];
	[textColor release];
	textColor = color;
	requiresUpdate = YES;
}

- (NSColor *) textColor
{
	return textColor;
}

#pragma mark Box Color

- (void) setBoxColor:(NSColor *)color // set default text color
{
	[color retain];
	[boxColor release];
	boxColor = color;
	requiresUpdate = YES;
}

- (NSColor *) boxColor
{
	return boxColor;
}

#pragma mark Border Color

- (void) setBorderColor:(NSColor *)color // set default text color
{
	[color retain];
	[borderColor release];
	borderColor = color;
	requiresUpdate = YES;
}

- (NSColor *) borderColor
{
	return borderColor;
}

#pragma mark Margin Size

// these will force the texture to be regenerated at the next draw
- (void) setMargins:(NSSize)size // set offset size and size to fit with offset
{
	marginSize = size;
    
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

- (NSSize) marginSize
{
	return marginSize;
}

#pragma mark Antialiasing
- (BOOL) antialias
{
	return antialias;
}

- (void) setAntialias:(bool)request
{
	antialias = request;
	requiresUpdate = YES;
}


#pragma mark Frame

- (NSSize) frameSize
{
    
	if ((NO == staticFrame) && (0.0f == frameSize.width) && (0.0f == frameSize.height)) { // find frame size if we have not already found it
		frameSize = [string size]; // current string size
		frameSize.width += marginSize.width * 2.0f; // add padding
		frameSize.height += marginSize.height * 2.0f;
	}
	return frameSize;
}

#pragma mark String

- (void) setString:(NSAttributedString *)attributedString // set string after initial creation
{
	[attributedString retain];
	[string release];
	string = attributedString;
    
	if (NO == staticFrame) { // ensure dynamic frame sizes will be recalculated
		frameSize.width = 0.0f;
		frameSize.height = 0.0f;
	}
	requiresUpdate = YES;
}

#pragma mark -
#pragma mark Drawing
// generates the texture (requires a current opengl context)
- (CVPixelBufferRef) drawOnBuffer:(CVPixelBufferRef)pixelBuffer
{
    
    [self genImage];
    
    size_t pxWidth = CVPixelBufferGetWidth(pixelBuffer);
    size_t pxHeight = CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *rasterData = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    // note that we are most likely going to write on a small area of the pixelbuffer
    // and memory could have been reused so we need to ensure emptying the entire frame
    // before actually drawing on it.
    // XXX - there could be a proper apple api to do this
    memset(rasterData, 0, bytesPerRow*pxHeight); 
    // context to draw in, set to pixel buffer's address
    size_t bitsPerComponent = 8; // *not* CGImageGetBitsPerComponent(image);
    CGColorSpaceRef cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
    CGContextRef ctxt = CGBitmapContextCreate(rasterData, pxWidth, pxHeight, bitsPerComponent, bytesPerRow, cs, kCGImageAlphaNoneSkipFirst);
    if(ctxt == NULL){
        NSLog(@"could not create context");
        CFRelease(cs);
        return NULL;
    }
    
    // draw at the center of the provided pixel buffer
    NSGraphicsContext *nsctxt = [NSGraphicsContext graphicsContextWithGraphicsPort:ctxt flipped:NO];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:nsctxt];
    [image compositeToPoint:NSMakePoint(round((pxWidth-frameSize.width)/2),
                                        round((pxHeight-frameSize.height)/2)) 
                  operation:NSCompositeCopy];
    [NSGraphicsContext restoreGraphicsState];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CFRelease(ctxt);
    CFRelease(cs);
    
    return pixelBuffer;
}

@end
