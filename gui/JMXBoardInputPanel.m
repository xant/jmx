//
//  JMXBoardInputPanel.m
//  JMX
//
//  Created by xant on 9/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXBoardInputPanel.h"

@implementation JMXBoardInputPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag];
    if (self) {
        pin = nil;
    }
    return self;
}

- (void)setPin:(JMXPin *)thePin
{
    NSArray *allowedValues;
    pin = thePin;
    [pinName setStringValue:pin.name];
    switch (pin.type) {
        case kJMXStringPin:
            allowedValues = [pin allowedValues];
            if (allowedValues && [allowedValues count]) {
                [inputFieldContainer selectTabViewItemAtIndex:3];
                NSTabViewItem *tabViewItem = [inputFieldContainer tabViewItemAtIndex:3];
                NSComboBox *cBox = [tabViewItem view];
                [cBox addItemsWithObjectValues:allowedValues];
            } else {
                [inputFieldContainer selectTabViewItemAtIndex:1];
            }
            break;
        default:
            // TODO - warning messages
            break;
    }
}

- (IBAction)sendInput:(id)sender
{
}

@end
