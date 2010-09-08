//
//  VJXSize.m
//  VeeJay
//
//  Created by xant on 9/5/10.
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

#import "VJXSize.h"


@implementation VJXSize

@synthesize nsSize;

+ (id)sizeWithNSSize:(NSSize)size
{
    id obj = [VJXSize alloc];
    return [[obj initWithNSSize:size] autorelease];
}

- (id)initWithNSSize:(NSSize)size
{
    if (self == [super init]) {
        self.nsSize = size;
    }
    return self;
}

- (id)init
{
    if (self = [super init])
        return [self initWithNSSize:NSZeroSize];
    return self;
}

- (CGFloat)width
{
    return nsSize.width;
}

- (CGFloat)height
{
    return nsSize.height;
}

@end
