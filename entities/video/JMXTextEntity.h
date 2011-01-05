//
//  JMXTextLayer.h
//  JMX
//
//  Created by xant on 10/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXVideoEntity.h"
#import "JMXTextRenderer.h"

@interface JMXTextEntity : JMXVideoEntity {
@private
    NSMutableDictionary *attributes;
    JMXTextRenderer *renderer;
    NSString *text;
    NSFont *font;
    NSColor *bgColor;
    NSColor *fgColor;
    bool needsNewFrame;
    NSDictionary *stanStringAttrib;
    CIImage *renderedText;
}

@property (retain) NSFont *font;
@property (retain) NSColor *bgColor;
@property (retain) NSColor *fgColor;

- (void)setText:(NSString *)newText;
- (void)setFontWithName:(NSString *)fontName;
- (void)setFontSize:(NSNumber *)fontSize;
- (void)setBackgroundColor:(NSColor *)color;
- (void)setBackgroundColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (void)setFontColor:(NSColor *)color;
- (void)setFontColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
@end

#ifdef __JMXV8__
JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXTextEntity);
#endif
