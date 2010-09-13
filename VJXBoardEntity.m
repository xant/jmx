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

    CGFloat pinSide = ENTITY_PIN_HEIGHT;
    CGFloat height = pinSide * maxNrPins * ENTITY_PIN_MINSPACING;
    CGFloat width = ENTITY_FRAME_WIDTH;
    
    NSTextField *labelView = [[[NSTextField alloc] init] autorelease];
    [labelView setTextColor:[NSColor whiteColor]];
    [labelView setStringValue:[theEntity displayName]];
    [labelView setBordered:NO];
    [labelView setEditable:NO];
    [labelView setDrawsBackground:NO];
    [labelView setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
    [labelView sizeToFit];
    CGFloat labelHeight = [labelView frame].size.height;
    NSRect frame = NSMakeRect(10.0, 10.0, width, height + labelHeight + ENTITY_LABEL_PADDING);
    CGRect labelFrame = [labelView frame];
    labelFrame.origin.x += ENTITY_LABEL_PADDING;
    labelFrame.origin.y = frame.size.height-labelHeight - ENTITY_LABEL_PADDING/2;
    [labelView setFrame:labelFrame];
    self = [super initWithFrame:frame];
    
    if (self) {
        self.label = labelView;
        [self addSubview:self.label];

        self.entity = theEntity;
        self.selected = NO;
        self.outlets = [NSMutableArray array];
        
        NSRect bounds = [self bounds];
        bounds.size.height -= (labelHeight + ENTITY_LABEL_PADDING);
        bounds.origin.x += ENTITY_PIN_LEFT_PADDING;
        
        NSUInteger nrInputPins = [theEntity.inputPins count];
        NSUInteger nrOutputPins = [theEntity.outputPins count];
        
        int i = 0;
        NSArray *pins = [[theEntity.inputPins allKeys]
                         sortedArrayUsingComparator:^(id obj1, id obj2)
                         {
                             return [obj1 compare:obj2];
                         }];
        for (NSString *pinName in pins) {
            NSPoint origin = NSMakePoint(bounds.origin.x, (((bounds.size.height / nrInputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.inputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:NO];
            [self addSubview:outlet];
            [self.outlets addObject:outlet];
            [outlet release];
        }
        
        pins = [[theEntity.outputPins allKeys]
                sortedArrayUsingComparator:^(id obj1, id obj2)
                {
                    return [obj1 compare:obj2];
                }];
        i = 0;
        for (NSString *pinName in pins) {
            NSPoint origin = NSMakePoint(bounds.size.width - ENTITY_OUTLET_WIDTH ,
                                         (((bounds.size.height / nrOutputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.outputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:YES];
            [self addSubview:outlet];
            [self.outlets addObject:outlet];
            [outlet release];
        }
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
    }

    // Whenever the selected status is changed, we need to redraw the entity.
    if (selected != isSelected)
        [self setNeedsDisplay:YES];

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
