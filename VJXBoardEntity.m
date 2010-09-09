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
        [self setEntity:theEntity];
        [self setSelected:NO];
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
        
        self.label = [[NSTextField alloc] initWithFrame:NSMakeRect(bounds.origin.x, (bounds.size.height - 4.0), bounds.size.width, labelHeight)];
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
    [super dealloc];
}

#define X_RADIUS 4.0
#define Y_RADIUS 4.0

- (void)drawRect:(NSRect)dirtyRect {
    
    NSShadow *dropShadow = [[[NSShadow alloc] init] autorelease];
    
    [dropShadow setShadowColor:[NSColor blackColor]];
    [dropShadow setShadowBlurRadius:2.5];
    [dropShadow setShadowOffset:NSMakeSize(2.0, -2.0)];
    
    [dropShadow set];
    
    NSRect bounds = [self bounds];
    NSBezierPath *thePath = nil;

    // Give enough room for outlets.
    bounds.origin.x += 4.0;
    bounds.origin.y += 4.0;
    bounds.size.width -= 2 * bounds.origin.x;
    bounds.size.height -= 2 * bounds.origin.y;

    NSRect rect = NSMakeRect(bounds.origin.x + 1.0,
                             bounds.origin.y + 1.0,
                             bounds.size.width - 2.0,
                             bounds.size.height - 2.0);
    thePath = [[NSBezierPath alloc] init];

    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];

    if (self.selected)
        [[NSColor yellowColor] setStroke];
    else 
        [[NSColor blackColor] setStroke];
    
    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:0.5 yBy:0.5];
    
    [thePath appendBezierPathWithRoundedRect:rect xRadius:X_RADIUS yRadius:Y_RADIUS];
    [thePath transformUsingAffineTransform:transform];
    [thePath fill];
    [thePath stroke];
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
    
    [[VJXBoard sharedBoard] setSelected:self];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    // Move the entity, recalculating the coordinates based on the current point
    // and the entity's frame.
    NSPoint newDragLocation = [theEvent locationInWindow];
    NSPoint thisOrigin = [self frame].origin;
    thisOrigin.x += (-lastDragLocation.x + newDragLocation.x);
    thisOrigin.y += (-lastDragLocation.y + newDragLocation.y);
    [self setFrameOrigin:thisOrigin];
    lastDragLocation = newDragLocation;
    
    // Update outlets' connectors coordinates as well.
    [self.outlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Cleanup last drag location.
    lastDragLocation = NSZeroPoint;
}

- (void)setSelected:(BOOL)isSelected
{
    // Whenever the selected status is changed, we need to redraw the entity.
    selected = isSelected;
    [self setNeedsDisplay:YES];
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (NSString *)description
{
    return [self.entity displayName];
}

- (void)removeFromSuperview
{
    [VJXBoard removeEntity:self];
    [super removeFromSuperview];
}

- (BOOL)inRect:(NSRect)rect
{
    NSRect frame = [self frame];
    NSPointArray points = calloc(4, sizeof(NSPoint));
    points[0] = NSMakePoint(frame.origin.x, frame.origin.y);
    points[1] = NSMakePoint(frame.origin.x, frame.origin.y + frame.size.height);
    points[2] = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y);
    points[3] = NSMakePoint(frame.origin.x + frame.size.width, frame.origin.y + frame.size.height);

    BOOL inRect = NO;
    
    for (int i = 0; i < 4; i++) {
        if ((inRect = NSPointInRect(points[i], rect)) == YES)
            break;
    }
    free(points);
    
    return inRect;
}

- (void)unselect
{
    [self setSelected:NO];
}

@end
