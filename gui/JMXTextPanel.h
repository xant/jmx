//
//  JMXTextPanel.h
//  JMX
//
//  Created by xant on 12/29/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JMXInputPin;

@interface JMXTextPanel : NSPanel < NSTextViewDelegate > {
    IBOutlet NSButton *updateButton;
    IBOutlet NSButton *liveButton;
    IBOutlet NSTextView *textView;
    JMXInputPin *pin;
}

@property (readwrite, assign) JMXInputPin *pin;
- (IBAction)update:(id)sender;

/*
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;    
*/
@end
