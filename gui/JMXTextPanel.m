//
//  JMXTextPanel.m
//  JMX
//
//  Created by xant on 12/29/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
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
    else if (pin)
        pin.data = [[textView textStorage] string];
}

- (void)unsetPin:(NSNotification *)notification
{
    self.pin = nil;
    [self setIsVisible:NO];
}

- (JMXInputPin *)pin
{
    @synchronized(self) {
        return [[pin retain] autorelease];
    }
}

- (void)setPin:(JMXInputPin *)aPin
{
    @synchronized(self) {
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
}

@end
