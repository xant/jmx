//
//  VJXScreen.m
//  VeeJay
//
//  Created by xant on 9/2/10.
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

#import "VJXScreen.h"


@implementation VJXScreen

@synthesize size;

- (id)initWithSize:(NSSize)screenSize
{
    if (self = [super init]) {
        currentFrame = nil;
        self.size = [VJXSize sizeWithNSSize:screenSize];    
        [self registerInputPin:@"inputFrame" withType:kVJXImagePin andSelector:@"drawFrame:"];
        [self registerInputPin:@"screenSize" withType:kVJXSizePin andSelector:@"setSize:"];

        // effective fps for debugging purposes
        [self registerOutputPin:@"fps" withType:kVJXNumberPin];
    }
    return self;
}

- (id)init
{
    if (self == [super init]) {
        NSSize defaultSize = { 640, 480 };
        return [self initWithSize:defaultSize];
    }
    return self;
}

- (void)drawFrame:(CIImage *)frame
{
    @synchronized(self) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [frame retain];
    }
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    self.size = nil;
    [super dealloc];
}

@end
