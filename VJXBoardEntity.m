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

@synthesize entity;

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

- (id)initWithEntity:(VJXEntity *)theEntity
{

    NSUInteger maxNrPins = MAX([theEntity.inputPins count], [theEntity.outputPins count]);

    CGFloat pinSide = 11.0;
    CGFloat height = pinSide * 2 * maxNrPins;
    CGFloat width = 100.0;
    
    NSRect frame = NSMakeRect(10.0, 10.0, width, height);
    
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setEntity:theEntity];
        NSRect bounds = [self bounds];
        
        NSUInteger nrInputPins = [theEntity.inputPins count];
        NSUInteger nrOutputPins = [theEntity.outputPins count];
        
        int i = 0;
        for (NSString *pinName in theEntity.inputPins) {
            NSLog(@"%@", pinName);
            NSRect outletRect = NSMakeRect(0.0, (((bounds.size.height / nrInputPins) * i++) - (bounds.origin.y - (3.0))), pinSide, pinSide);
            VJXBoardEntityPin *outlet = [[VJXBoardEntityPin alloc] initWithFrame:outletRect];
            outlet.pin = [theEntity.inputPins objectForKey:pinName];
            [self addSubview:outlet];
        }
        
        i = 0;
        for (NSString *pinName in theEntity.outputPins) {
            NSLog(@"%@", pinName);
            NSRect outletRect = NSMakeRect(bounds.size.width - pinSide, (((bounds.size.height / nrOutputPins) * i++) - (bounds.origin.y - (3.0))), pinSide, pinSide);
            VJXBoardEntityPin *outlet = [[VJXBoardEntityPin alloc] initWithFrame:outletRect];
            outlet.pin = [theEntity.outputPins objectForKey:pinName];
            [self addSubview:outlet];
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
