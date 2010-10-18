//
//  VJXOutputPin.h
//  VeeJay
//
//  Created by xant on 10/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import "VJXPin.h"

@class VJXInputPin;

@interface VJXOutputPin : VJXPin {
    NSMutableDictionary *receivers;

}

@property (readonly)  NSDictionary *receivers;

- (void)deliverSignal:(id)data fromSender:(id)sender;
- (void)deliverSignal:(id)data;
- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal;
- (void)detachObject:(id)pinReceiver;
- (BOOL)connectToPin:(VJXInputPin *)destinationPin;
- (void)disconnectFromPin:(VJXInputPin *)destinationPin;
@end
