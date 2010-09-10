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

@synthesize currentSelection, entities;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.entities = [NSMutableArray array];
        [self setSelected:nil multiple:NO];
    }
    return self;
}

- (void)awakeFromNib
{
    self.entities = [NSMutableArray array];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    NSBezierPath *thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithRect:[self bounds]];
    [thePath fill];
    [thePath release];
}

- (void)addToBoard:(VJXBoardEntity *)theEntity
{
    [self addSubview:theEntity];
    [entities addObject:theEntity];

    // Put focus on the created entity.
    [self setSelected:theEntity multiple:NO];
}

- (void)setSelected:(VJXBoardEntity *)theEntity multiple:(BOOL)isMultiple
{
    // Add some point, we'll be using a NSArrayController to have references of
    // all entities we have on the board, so the entity selection will be done
    // thru it instead of this code. Using NSArrayController for that will be 
    // nice because we can use KVC in IB to create the Inspector palettes.

    // Unselect all entities, and toggle only the one we selected.
    if (!isMultiple)
        [entities makeObjectsPerformSelector:@selector(unselect)];

    [theEntity toggleSelected];
    
    // Move the selected entity to the end of the subviews array, making it move
    // to the top of the view hierarchy.
    if ([entities count] >= 1) {
        NSMutableArray *subviews = [[self subviews] mutableCopy];
        [subviews removeObjectAtIndex:[subviews indexOfObject:theEntity]];
        [subviews addObject:theEntity];
        [self setSubviews:subviews];
        [subviews release];
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    lastDragLocation = [theEvent locationInWindow];

    // Unselect all the selected entities if the user click on the board.
    [entities makeObjectsPerformSelector:@selector(unselect)]; 
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint thisLocation = [theEvent locationInWindow];

    // Create a view VJXBoardSelection and place it in the top of the view
    // hierarchy if it already doesn't exist.
    if (!currentSelection) {
        self.currentSelection = [[[VJXBoardSelection alloc] init] autorelease];
        [self addSubview:currentSelection positioned:NSWindowAbove relativeTo:nil];
    }
    
    // Calculate the frame based on the window's coordinates and set the rect
    // as the current selection frame.
    [currentSelection setFrame:NSMakeRect(MIN(thisLocation.x, lastDragLocation.x),
                                          MIN(thisLocation.y, lastDragLocation.y), 
                                          abs(thisLocation.x - lastDragLocation.x), 
                                          abs(thisLocation.y - lastDragLocation.y))];
    
    for (VJXBoardEntity *entity in [self entities]) {
        // Unselect the entity. We'll have all the entities unselected as net
        // result of this operation, if the entity isn't inside the current 
        // selection rect.
        [entity setSelected:[entity inRect:[currentSelection frame]]];
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
    // XXX - here a create-on-first-use idiom should be adopted
    //       and if this class is going to be used as singleton,
    //       new instances shold be forbiddend and constructors/initializers
    //       should be private
    return sharedBoard;
}

// XXX - such a message shouldn't exist at all
//       the shared 'singleton' instance should be created
//       transparently the first time it is requested
+ (void)setSharedBoard:(VJXBoard *)aBoard
{
    sharedBoard = aBoard;
}

+ (void)shiftSelectedToLocation:(NSPoint)aLocation
{
    [[self sharedBoard] shiftSelectedToLocation:aLocation];
}

- (void)shiftSelectedToLocation:(NSPoint)aLocation;
{
    for (VJXBoardEntity *e in [self entities]) {
        if (e.selected)
            [e shiftOffsetToLocation:aLocation];
    }
}

- (BOOL)hasMultipleEntitiesSelected
{
    NSUInteger count = 0;
    for (VJXBoardEntity *e in [self entities]) {
        if (e.selected)
            count++;
        if (count > 1)
            return YES;
    }
    return NO;
}

- (void)removeSelectedEntities
{
    for (VJXBoardEntity *e in entities) {
        if (e.selected) {
            // Remove the entity from the superview.
            //
            // It seems removeFromSuperview autoreleases the view, instead of
            // releasing it at the time we remove it, so retainCount won't be
            // updated until the end of the run loop.
            [e removeFromSuperview];

            // Remove the entity from our entities array, since we won't need
            // it anymore.
            [entities removeObject:e];
            NSLog(@"retainCount: %i", [e retainCount]);
        }
    }
}

@end
