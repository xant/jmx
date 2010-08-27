//
//  VJXBoardComponent.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntity.h"
#import "VJXBoardEntityPin.h"

@implementation VJXBoardEntity

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        NSRect bounds = [self bounds];

        // Input outlets
        NSUInteger nrOutlets = (rand() % 4)+1;
        for (NSUInteger i = 0; i < nrOutlets; i++) {
            NSRect outletRect = NSMakeRect(0.0, (((bounds.size.height / nrOutlets) * i) - (bounds.origin.y - (3.0))), 11.0, 11.0);
            VJXBoardEntityPin *outlet = [[VJXBoardEntityPin alloc] initWithFrame:outletRect];
            [self addSubview:outlet];
        }

        // Output outlets
        for (NSUInteger i = 0; i < nrOutlets; i++) {

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

    [[NSColor whiteColor] set];
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
    lastDragLocation = [theEvent locationInWindow];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint newDragLocation = [theEvent locationInWindow];
    NSPoint thisOrigin = [self frame].origin;
    thisOrigin.x += (-lastDragLocation.x + newDragLocation.x);
    thisOrigin.y += (-lastDragLocation.y + newDragLocation.y);
    [self setFrameOrigin:thisOrigin];
    lastDragLocation = newDragLocation;
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

@end
