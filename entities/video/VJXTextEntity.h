//
//  VJXTextLayer.h
//  VeeJay
//
//  Created by xant on 10/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXVideoEntity.h"
#import "VJXTextRenderer.h"

@interface VJXTextEntity : VJXVideoEntity {
@private
    NSMutableDictionary *attributes;
    VJXTextRenderer *renderer;
    NSString *text;
    NSFont *font;
    NSColor *bgColor;
    NSColor *fgColor;
    bool needsNewFrame;
    NSDictionary *stanStringAttrib;
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
