//
//  JMXTextLayer.m
//  JMX
//
//  Created by xant on 10/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXTextEntity.h"

@implementation JMXTextEntity

@synthesize font, bgColor, fgColor;
- (id)init
{
    self = [super init];
    if (self) {
        self.frequency = [NSNumber numberWithDouble:25.0];
        [self registerInputPin:@"fontName"
                      withType:kJMXStringPin
                   andSelector:@"setFontWithName:"
                 allowedValues:[[NSFontManager sharedFontManager] availableFonts]
                  initialValue:[[NSFont systemFontOfSize:[NSFont systemFontSize]] fontName]];
        [self registerInputPin:@"inputText" withType:kJMXTextPin andSelector:@"setText:"];
        [self registerInputPin:@"fontSize" withType:kJMXNumberPin andSelector:@"setFontSize:"];
        [self registerInputPin:@"fontColor" withType:kJMXColorPin andSelector:@"setFontColor:"];
        [self registerInputPin:@"backgroundColor" withType:kJMXColorPin andSelector:@"setBackgroundColor:"];
        attributes = [[NSMutableDictionary dictionary] retain];
        self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        self.fgColor = [NSColor whiteColor];
        self.bgColor = [NSColor blackColor];
        [attributes
         setObject:font
         forKey:NSFontAttributeName
         ];
        [attributes
         setObject:fgColor
         forKey:NSForegroundColorAttributeName
         ];
        [attributes
         setObject:bgColor
         forKey:NSBackgroundColorAttributeName
         ];
        renderer = [[JMXTextRenderer alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [renderer release];
    [attributes release];
    [super dealloc];
}

- (void)renderText
{
    //if (needsNewFrame) {
    stanStringAttrib = attributes;
    CVPixelBufferRef textFrame;
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:size.width], kCVPixelBufferWidthKey,
                       [NSNumber numberWithInt:size.height], kCVPixelBufferHeightKey,
                       [NSNumber numberWithInt:size.width*4],kCVPixelBufferBytesPerRowAlignmentKey,
                       [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, 
                       [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, 
                       [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                       nil];
    
    // create pixel buffer
    CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault,
                                       size.width,
                                       size.height,
                                       k32ARGBPixelFormat,
                                       (CFDictionaryRef)d,
                                       &textFrame);
    if (ret == noErr) {
        // TODO - Implement properly
        //NSFont * font =[NSFont fontWithName:@"Helvetica" size:32.0];
        [renderer initWithString:text withAttributes:stanStringAttrib];
        [renderer drawOnBuffer:textFrame];
        @synchronized(self) {
            if (currentFrame)
                [currentFrame release];
            currentFrame = [[CIImage imageWithCVImageBuffer:textFrame] retain];
        }
        CVPixelBufferRelease(textFrame);
        needsNewFrame = NO;
    } else {
        // TODO - Error Messages
    }
    //}
}

- (void)setSize:(JMXSize *)theSize
{
    [super setSize:theSize];
    [self renderText];
}

- (void)setBackgroundColor:(NSColor *)color
{
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSBackgroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setBackgroundColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)transparency
{
    NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:transparency];
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSBackgroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontColor:(NSColor *)color
{
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSForegroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)transparency
{
    NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:transparency];
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSForegroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontSize:(NSNumber *)fontSize
{
    NSFont *newFont = [NSFont fontWithName:[self.font fontName] size:[fontSize floatValue]];
    if (newFont) {
        self.font = newFont;
        @synchronized(self) {
            [attributes setObject:newFont forKey:NSFontAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontWithName:(NSString *)fontName
{
    NSFont *newFont = [NSFont fontWithName:fontName size:[self.font pointSize]];
    if (newFont) {
        self.font = newFont;
        @synchronized(self) {
            [attributes setObject:newFont forKey:NSFontAttributeName];
        }
        [self renderText];
    }
}

- (void)setText:(NSString *)newText
{
    if (text)
        [text release];
    text = [newText retain];
    [self renderText];
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        [outputFramePin deliverData:currentFrame];
    }
    [self outputDefaultSignals:timeStamp];
}


@end
