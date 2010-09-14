//
//  VJXBoardInputPanel.h
//  VeeJay
//
//  Created by xant on 9/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXPin.h"

@interface VJXBoardInputPanel : NSPanel {
    IBOutlet NSTextField *pinName;
    IBOutlet NSTabView *inputFieldContainer;
    VJXPin *pin;
}

- (void)setPin:(VJXPin *)thePin;
- (IBAction)sendInput:(id)sender;

@end
