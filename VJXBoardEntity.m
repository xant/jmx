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

@implementation VJXBoardEntity

@synthesize entity;

- (id)initWithEntity:(VJXEntity *)theEntity
{

    NSUInteger maxNrPins = MAX([theEntity.inputPins count], [theEntity.outputPins count]);

    CGFloat pinSide = 11.0;
    CGFloat height = pinSide * 2 * maxNrPins;
    CGFloat width = 300.0;
    
    NSRect frame = NSMakeRect(10.0, 10.0, width, height);
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setEntity:theEntity];
        NSRect bounds = [self bounds];
        
        NSUInteger nrInputPins = [theEntity.inputPins count];
        NSUInteger nrOutputPins = [theEntity.outputPins count];
        
        int i = 0;
        for (NSString *pinName in theEntity.inputPins) {
            NSPoint origin = NSMakePoint(0.0, (((bounds.size.height / nrInputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.inputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:NO];
            [self addSubview:outlet];
            [outlet release];
        }
        
        i = 0;
        for (NSString *pinName in theEntity.outputPins) {
            NSLog(@"%@", pinName);
            NSPoint origin = NSMakePoint(bounds.size.width - 120.0,
                                         (((bounds.size.height / nrOutputPins) * i++) - (bounds.origin.y - (3.0))));
            VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[theEntity.outputPins objectForKey:pinName]
                                                                            andPoint:origin
                                                                            isOutput:YES];
            [self addSubview:outlet];
            [outlet release];
        }
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
    NSRect bounds = [self bounds];
    NSBezierPath *thePath = nil;

    // Give enough room for outlets.
    bounds.origin.x += 2.0;
    bounds.origin.y += 2.0;
    bounds.size.width -= 4.0;
    bounds.size.height -= 4.0;

    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] set];

    NSRect rect = NSMakeRect(bounds.origin.x + .5,
                             bounds.origin.y + .5,
                             bounds.size.width - 1.0,
                             bounds.size.height - 1.0);
    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithRoundedRect:rect xRadius:X_RADIUS yRadius:Y_RADIUS];
    [thePath fill];

    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithRoundedRect:bounds xRadius:X_RADIUS yRadius:Y_RADIUS];
    [[NSColor blackColor] set];
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
    
    // Update pins' connectors coordinates as well.
    [[self subviews] makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];    
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Cleanup last drag location.
    lastDragLocation = NSZeroPoint;
}

@end
