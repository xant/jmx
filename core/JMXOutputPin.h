//
//  JMXOutputPin.h
//  JMX
//
//  Created by xant on 10/18/10.
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
#import "JMXPin.h"

@class JMXInputPin;

@interface JMXOutputPin : JMXPin {
    NSMutableDictionary *receivers;

}

@property (readonly)  NSDictionary *receivers;

- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal;
- (void)detachObject:(id)pinReceiver;
- (BOOL)connectToPin:(JMXInputPin *)destinationPin;
- (void)disconnectFromPin:(JMXInputPin *)destinationPin;
@end
