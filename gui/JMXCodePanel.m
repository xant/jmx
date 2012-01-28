//
//  JMXCodePanel.m
//  JMX
//
//  Created by Andrea Guzzo on 1/5/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXCodePanel.h"
#import "JMXInputPin.h"
#import "JMXEntity.h"

@implementation JMXCodePanel

- (id)initWithContentRect:(NSRect)contentRect 
                styleMask:(NSUInteger)aStyle 
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect
                            styleMask:aStyle
                              backing:bufferingType
                                defer:flag];
    if (self) {
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)setIsVisible:(BOOL)flag
{
    [super setIsVisible:flag];
    if (flag)
        textView.editable = NO;
}

- (IBAction)update:(id)sender
{
    NSString *text = codeText.stringValue;
    if (!text || ![text length])
        return;
    
    if ([self delegate]) {
        [[self delegate] performSelector:@selector(setText:)
                              withObject:text];
    } else if (pin) {
        pin.data = text;
    }
    if (pin && pin.type == kJMXCodePin) {
        NSString *statement = [NSString stringWithFormat:@"%@\n", text];
        NSAttributedString *attributedString = [[[NSAttributedString alloc]
                                                 initWithString:statement] autorelease];
        [textView.textStorage appendAttributedString:attributedString];
        textView.needsDisplay = YES;
        codeText.stringValue = @"";
    }
}

- (void)unsetPin:(NSNotification *)notification
{
    @synchronized(textBuffer) {
        [textBuffer setString:@""];
    }
    self.pin = nil;
    [self setIsVisible:NO];
}

- (void)setPin:(JMXInputPin *)aPin
{
    @synchronized(self) {
        [super setPin:aPin];
        if (aPin && aPin.type == kJMXCodePin) {
            // if this is a code pin, let's retrieve the actual code being executed
            id owner = aPin.owner;
            if (![owner isKindOfClass:[JMXEntity class]])
                return;
            JMXEntity *entity = (JMXEntity *)owner;
            JMXPin *outputCodePin = nil;
            for (JMXOutputPin *outputPin in [entity outputPins]) {
                if (outputPin.type == kJMXCodePin) {
                    outputCodePin = outputPin;
                    break;
                }
            }
            if (!outputCodePin)
                return;
            //NSString *text = [[textView textStorage] string];
            [textView setString:@""];
            NSString *data = outputCodePin.data;
            if (data)
                [textView insertText:(NSString *)outputCodePin.data];
        }
    }
}

@end
