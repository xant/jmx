//
//  JMXTextPanel.m
//  JMX
//
//  Created by xant on 12/29/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXTextPanel.h"
#import "JMXInputPin.h"

@implementation JMXTextPanel

@synthesize pin;

- (void)awakeFromNib
{
    pin = nil;
}

- (void)textDidChange:(NSNotification *)aNotification
{
    NSTextView *aTextView = [aNotification object];
    if ([liveButton state] == NSOnState) {
        if ([self delegate])
            [[self delegate] performSelector:@selector(setText:) withObject:[[aTextView textStorage] string]];
        else if (pin)
            pin.data = [[aTextView textStorage] string];
    }
}

- (void)textDidBeginEditing:(NSNotification *)aNotification
{
}

- (void)textDidEndEditing:(NSNotification *)aNotification
{
}

- (BOOL)textShouldBeginEditing:(NSText *)aTextObject
{
    return YES;
}

- (BOOL)textShouldEndEditing:(NSText *)aTextObject
{
    return YES;
}

- (IBAction)update:(id)sender
{
    if ([self delegate])
        [[self delegate] performSelector:@selector(setText:) withObject:[[textView textStorage] string]];
}

- (void)unsetPin:(NSNotification *)notification
{
    self.pin = nil;
    [self setIsVisible:NO];
}

- (void)setPin:(JMXInputPin *)aPin
{
    if (pin != aPin) {
        [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                        name:@"JMXEntityInputPinRemoved" 
                                                      object:pin.owner];
        pin = aPin;
        if (pin) {
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(unsetPin:)
                                                         name:@"JMXEntityInputPinRemoved" 
                                                       object:pin.owner];
        }
    }
}

@end
