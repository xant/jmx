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

@synthesize selectedEntity, currentSelection;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setSelected:nil];
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
        [self setSelected:(VJXBoardEntity *)aView];        
    }
}

- (void)setSelected:(id)theEntity
{
    // Add some point, we'll be using a NSArrayController to have references of
    // all entities we have on the board, so the entity selection will be done
    // thru it instead of this code. Using NSArrayController for that will be 
    // nice because we can use KVC in IB to create the Inspector palettes.
    
    if (theEntity != selectedEntity) {
        [selectedEntity toggleSelected];
        [selectedEntity release];
        selectedEntity = [theEntity retain];
        [selectedEntity toggleSelected];
    }

    // Move the selected entity to the end of the subviews array, making it move
    // to the top of the view hierarchy.
    if ([theEntity isKindOfClass:[VJXBoardEntity class]] && ([[self subviews] count] >= 1)) {
        NSMutableArray *subviews = [[self subviews] mutableCopy];
        [subviews removeObjectAtIndex:[subviews indexOfObject:selectedEntity]];
        [subviews addObject:selectedEntity];
        [self setSubviews:subviews];
        NSLog(@"%@", subviews);
        [subviews release];
    }
    
}

- (void)mouseDown:(NSEvent *)theEvent
{
    lastDragLocation = [theEvent locationInWindow];
    [self.selectedEntity toggleSelected];
    self.selectedEntity = nil;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint thisLocation = [theEvent locationInWindow];
    
    if (!currentSelection) {
        self.currentSelection = [[VJXBoardSelection alloc] init];
        [self addSubview:currentSelection positioned:NSWindowAbove relativeTo:nil];
    }
    
    CGFloat x, y, w, h;
    x = MIN(thisLocation.x, lastDragLocation.x);
    y = MIN(thisLocation.y, lastDragLocation.y);
    w = abs(thisLocation.x - lastDragLocation.x);
    h = abs(thisLocation.y - lastDragLocation.y);
    
    [currentSelection setFrame:NSMakeRect(x, y, w, h)];
    
    for (VJXBoardEntity *entity in [self subviews]) {
        if (![entity isKindOfClass:[VJXBoardEntity class]])
            continue;
        
        NSPointArray points = [entity points];
        for (int i = 0; i < 4; i++) {
            if (NSPointInRect(points[i], [currentSelection frame])) {
                [entity setSelected:YES];
                break;
            }
        }
        free(points);
    }
    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [currentSelection removeFromSuperview];
    self.currentSelection = nil;
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
