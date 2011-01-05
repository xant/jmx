//
//  JMXTextPanel.h
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

#import <Cocoa/Cocoa.h>

@class JMXInputPin;

@interface JMXTextPanel : NSPanel < NSTextViewDelegate > {
    IBOutlet NSButton *updateButton;
    IBOutlet NSButton *liveButton;
    IBOutlet NSTextView *textView;
    JMXInputPin *pin;
}

@property (readwrite, assign) JMXInputPin *pin; // weak reference
- (IBAction)update:(id)sender;

/*
- (void)setTarget:(id)aTarget;
- (void)setAction:(SEL)anAction;    
*/
@end
