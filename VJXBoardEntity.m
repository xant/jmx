//
//  VJXBoardComponent.m
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

#import "VJXBoardEntity.h"
#import "VJXBoardEntityPin.h"
#import "VJXBoardEntityOutlet.h"
#import "VJXBoardDelegate.h"
#import "VJXEntityInspector.h";

@implementation VJXBoardEntity

@synthesize entity, label, selected, outlets;

- (id)initWithEntity:(VJXEntity *)theEntity
{

    NSUInteger maxNrPins = MAX([theEntity.inputPins count], [theEntity.outputPins count]);

    CGFloat labelHeight = 32.0;
    CGFloat pinSide = 11.0;
    CGFloat height = pinSide * 2 * maxNrPins;
    CGFloat width = 300.0;
    
    NSRect frame = NSMakeRect(10.0, 10.0, width, height + labelHeight);
    
    self = [super initWithFrame:frame];
    
    if (self) {
        self.entity = theEntity;
        self.selected = NO;
        self.outlets = [NSMutableArray array];
        
        NSRect bounds = [self bounds];
        bounds.size.height -= labelHeight;
        bounds.origin.x += 6.0;
        bounds.origin.y -= 6.0;
        
        NSUInteger nrInputPins = [theEntity.inputPins count];
        NSUInteger nrOutputPins = [theEntity.outputPins count];
        
        int i = 0;
        for (NSString *pinName in theEntity.inputPins) {
            NSPoint origin = NSMakePoint(bounds.origin.x, (((bounds.size.height / nrInputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.inputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:NO];
            [self addSubview:outlet];
            [self.outlets addObject:outlet];
            [outlet release];
        }
        
        i = 0;
        for (NSString *pinName in theEntity.outputPins) {
            NSPoint origin = NSMakePoint(bounds.size.width - 120.0,
                                         (((bounds.size.height / nrOutputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.outputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:YES];
            [self addSubview:outlet];
            [self.outlets addObject:outlet];
            [outlet release];
        }
        
        self.label = [[[NSTextField alloc] initWithFrame:NSMakeRect(bounds.origin.x, (bounds.size.height - 4.0), bounds.size.width, labelHeight)] autorelease];
        [self.label setTextColor:[NSColor whiteColor]];
        [self.label setStringValue:[self.entity displayName]];
        [self.label setBordered:NO];
        [self.label setEditable:NO];
        [self.label setDrawsBackground:NO];
        [self addSubview:self.label];        
    }
    return self;
}

- (void)dealloc
{
    if ([entity respondsToSelector:@selector(stop)])
        [entity performSelector:@selector(stop)];
    // we need to ensure telling the inspector 
    // that we are going to be destroyed, since 
    // it could still referencing us
    // TODO - we could check this only if we are selected
    [VJXEntityInspector unsetEntity:self];
    [entity release];
    [label release];
    [outlets release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    
    NSShadow *dropShadow = [[[NSShadow alloc] init] autorelease];
    
    [dropShadow setShadowColor:[NSColor blackColor]];
    [dropShadow setShadowBlurRadius:2.5];
    [dropShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
    
    [dropShadow set];
    
    NSBezierPath *thePath = nil;

    NSRect rect = NSOffsetRect([self bounds], 4.0, 4.0);
    rect.size.width -= 8.0;
    rect.size.height -= 8.0;

    thePath = [[NSBezierPath alloc] init];

    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];

    if (self.selected)
        [[NSColor yellowColor] setStroke];
    else 
        [[NSColor blackColor] setStroke];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:0.5 yBy:0.5];
    [thePath appendBezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    [thePath transformUsingAffineTransform:transform];
    [thePath fill];
    [thePath stroke];
    [thePath release];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // Here we keep track of our initial location, so when mouseDragged: message
    // is called it knows the last drag location.
    lastDragLocation = [theEvent locationInWindow];
    
    // If we have the Command key pressed, we assume the user wants to select
    // several entities so we add the entity to the selection. If we have other
    // entities selected (more than one) we don't do anything since we assume
    // the user want to move the selected entities. If we don't have several
    // entities selected, we unfocus the current selection and focus the 
    // one clicked.
    BOOL isMultiple = [theEvent modifierFlags] & NSCommandKeyMask ? YES : NO;
    if (isMultiple) {
        [[VJXBoard sharedBoard] setSelected:self multiple:YES];        
    }
    else {
        if (![[VJXBoard sharedBoard] hasMultipleEntitiesSelected]) {
            [[VJXBoard sharedBoard] setSelected:self multiple:NO];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    // Calculate the new location based on the last drag location and the 
    // location, then ask the board to shift all the selected elements to the
    // new point.
    NSPoint newDragLocation = [theEvent locationInWindow];
    NSPoint newLocation = NSMakePoint((-lastDragLocation.x + newDragLocation.x), (-lastDragLocation.y + newDragLocation.y));
    [[VJXBoard sharedBoard] shiftSelectedToLocation:newLocation];
    lastDragLocation = newDragLocation;
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Cleanup last drag location.
    lastDragLocation = NSZeroPoint;
}

- (void)setSelected:(BOOL)isSelected
{
    // reopen the inspector panel only if this is a new selection
    if (isSelected && !selected) {
        [VJXEntityInspector setEntity:self];
        [self setNeedsDisplay:YES];
    }
    // Whenever the selected status is changed, we need to redraw the entity.
    selected = isSelected;
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (NSString *)description
{
    return [self.entity displayName];
}

- (BOOL)inRect:(NSRect)rect
{
    return NSIntersectsRect(rect, [self frame]);
}

- (void)unselect
{
    [self setSelected:NO];
}

- (void)shiftOffsetToLocation:(NSPoint)aLocation
{
    NSRect thisFrame = NSOffsetRect([self frame], aLocation.x, aLocation.y);
    [self setFrame:thisFrame];
    [outlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
}

@end
