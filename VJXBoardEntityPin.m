//
//  VJXBoardComponentOutlet.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntityPin.h"

@implementation VJXBoardEntityPin

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *thePath = nil;

    [[NSColor redColor] set];
    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithOvalInRect:[self bounds]];
    [thePath fill];
    [thePath release];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
}

#define SOUTHWEST 0
#define SOUTHEAST 1
#define NORTHWEST 2
#define NORTHEAST 3

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!connector) {
        NSLog(@"connector created");
        connector = [[VJXBoardEntityConnector alloc] init];
        [self.superview.superview addSubview:connector];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];
    NSPoint thisLocation = [self.superview.superview convertPoint:[self bounds].origin fromView:self];

    NSRect bounds = [self bounds];

    thisLocation.x += (NSWidth(bounds) / 2);
    thisLocation.y += (NSHeight(bounds) / 2);

    float minX = MIN(locationInWindow.x, thisLocation.x);
    float minY = MIN(locationInWindow.y, thisLocation.y);
    float width = abs(locationInWindow.x - thisLocation.x);
    float height = abs(locationInWindow.y - thisLocation.y);

    if (width < 5.0) {
        width = 5.0;
    }
    if (height < 5.0) {
        height = 5.0;
    }

    if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        connector.direction = SOUTHWEST;
    }
    else if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        connector.direction = SOUTHEAST;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        connector.direction = NORTHWEST;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        connector.direction = NORTHEAST;
    }

    NSLog(@"direction:%i", connector.direction);


    NSRect frame = NSMakeRect(minX, minY, width, height);
    [connector setFrame:frame];
    [self.superview setNeedsDisplay:YES];

}

- (void)mouseUp:(NSEvent *)theEvent
{
    [connector removeFromSuperview];
    [connector release];
    connector = nil;
}

@end
