//
//  VJXBoardComponentOutlet.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntityPin.h"
#import "VJXBoardDelegate.h"
#import "VJXBoardEntityConnector.h"

@implementation VJXBoardEntityPin

@synthesize pin, connector;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    NSBezierPath *thePath = nil;

    [[NSColor redColor] set];
    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithOvalInRect:[self bounds]];
    [thePath fill];
    [thePath release];

    //    VJXBoardEntityPin *origin = [connector origin];
    //    VJXBoardEntityPin *destination = [connector destination];
    //
    //    NSPoint originPoint = [connector.superview.superview convertPoint:origin.frame.origin fromView:origin];
    //    NSPoint destinationPoint = [connector.superview.superview convertPoint:destination.frame.origin fromView:destination];
    //
    //    float x = MIN(originPoint.x, destinationPoint.x);
    //    float y = MIN(originPoint.y, destinationPoint.y);
    //    float w = abs(originPoint.x - destinationPoint.x);
    //    float h = abs(originPoint.y - destinationPoint.y);
    //
    //    NSRect connectorFrame = NSMakeRect(x, y, w, h);
    //    [connector setFrame:connectorFrame];
    //    [connector setNeedsDisplay:YES];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{

}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationInWindow = [theEvent locationInWindow];

    NSView *aView = [self.superview.superview hitTest:locationInWindow];

    if ([aView isKindOfClass:[VJXBoardEntityPin class]]) {
        VJXBoardEntityPin *otherPin = (VJXBoardEntityPin *)aView;
        NSLog(@"this Pin: %@, other Pin: %@", self.pin.name, otherPin.pin.name);
        [otherPin.pin connectToPin:self.pin];

        otherPin.connector = self.connector;
        [connector setOrigin:self];
        [connector setDestination:otherPin];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!connector) {
        connector = [[VJXBoardEntityConnector alloc] init];
        [connector setOrigin:self];
        [[VJXBoardDelegate sharedBoard] addSubview:connector positioned:0 relativeTo:nil];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];

    NSPoint thisLocation = [self convertPoint:[self bounds].origin toView:[VJXBoardDelegate sharedBoard]];

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
        connector.direction = kSouthWestDirection;
    }
    else if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        connector.direction = kSouthEastDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        connector.direction = kNorthWestDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        connector.direction = kNorthEastDirection;
    }

    NSRect frame = NSMakeRect(minX, minY, width, height);
    [connector setFrame:frame];
    [self.superview setNeedsDisplay:YES];

}

- (NSPoint)pointAtCenter
{
    NSPoint origin = [self frame].origin;
    NSSize size = [self frame].size;
    NSPoint center = NSMakePoint(origin.x + (size.width / 2),
        origin.y + (size.height / 2));
    return center;
}

- (void)updateAllConnectorsFrames
{
    [self.connector recalculateFrame];
}

@end
