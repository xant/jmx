//
//  JMXBoardInputPanel.h
//  JMX
//
//  Created by xant on 9/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXPin.h"

@interface JMXBoardInputPanel : NSPanel {
    IBOutlet NSTextField *pinName;
    IBOutlet NSTabView *inputFieldContainer;
    JMXPin *pin;
}

- (void)setPin:(JMXPin *)thePin;
- (IBAction)sendInput:(id)sender;

@end
