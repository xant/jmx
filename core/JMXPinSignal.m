//
//  JMXPinSignal.m
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

#import "JMXPinSignal.h"


@implementation JMXPinSignal

@synthesize sender, data, receiver;

+ (id)signalFromSender:(id)sender receiver:(id)receiver data:(id)data
{
    id signal = [JMXPinSignal alloc];
    if (signal) {
        return [[signal initWithSender:sender receiver:receiver data:data] autorelease];
    }
    return nil;
}

- (id)initWithSender:(id)theSender receiver:(id)theReceiver data:(id)theData
{
    self = [super init];
    if (self) {
        sender = [theSender retain];
        data = [theData retain];
        receiver = [theReceiver retain];
    }
    return self;
}

- (void)dealloc
{
    if (sender)
        [sender release];
    if (data)
        [data release];
    if (receiver)
        [receiver release];
    [super dealloc];
}

@end

