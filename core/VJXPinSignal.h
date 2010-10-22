//
//  VJXPinSignal.h
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
// NOTE : You don't need to use this class directly,
//        it's meant to be used internally by Pin implementations
#import <Cocoa/Cocoa.h>


@interface VJXPinSignal : NSObject {
    id data;
    id sender;
    id receiver;
}

@property (retain) id data;
@property (retain) id sender;
@property (retain) id receiver;

+ signalFromSender:(id)sender receiver:(id)receiver data:(id)data;
- (id)initWithSender:(id)theSender receiver:(id)theReceiver data:(id)theData;

@end