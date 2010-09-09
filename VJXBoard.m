//
//  VJXBoard.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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

#import "VJXBoard.h"


@implementation VJXBoard

@synthesize selectedEntity;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelectedEntity:nil];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    NSBezierPath *thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithRect:[self bounds]];
    [thePath fill];
    [thePath release];
}

- (void)addSubview:(NSView *)aView
{
    [super addSubview:aView];
    if ([aView isKindOfClass:[VJXBoardEntity class]]) {
        [self setSelectedEntity:(VJXBoardEntity *)aView];        
    }
}

- (void)setSelectedEntity:(VJXBoardEntity *)theEntity
{
    // Add some point, we'll be using a NSArrayController to have references of
    // all entities we have on the board, so the entity selection will be done
    // thru it instead of this code. Using NSArrayController for that will be 
    // nice because we can use KVC in IB to create the Inspector palettes.
    
    if (theEntity != selectedEntity) {
        [selectedEntity setSelected:NO];
        [selectedEntity release];
        selectedEntity = [theEntity retain];
        [selectedEntity setSelected:YES];        
    }

    // Move the selected entity to the end of the subviews array, making it move
    // to the top of the view hierarchy.
    if ([[self subviews] count] >= 1) {
        NSMutableArray *subviews = [[self subviews] mutableCopy];
        [subviews removeObjectAtIndex:[subviews indexOfObject:selectedEntity]];
        [subviews addObject:selectedEntity];
        [self setSubviews:subviews];
        NSLog(@"%@", subviews);
        [subviews release];
    }
    
}

static VJXBoard *sharedBoard = nil;

+ (VJXBoard *)sharedBoard
{
    return sharedBoard;
}

+ (void)setSharedBoard:(VJXBoard *)aBoard
{
    sharedBoard = aBoard;
}

@end
