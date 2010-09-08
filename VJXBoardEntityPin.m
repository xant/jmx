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

@synthesize pin, tempConnector, connectors;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.connectors = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.connectors = nil;
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
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{

}

- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!tempConnector) {
        tempConnector = [[VJXBoardEntityConnector alloc] init];
        [tempConnector setOrigin:self];
        [[VJXBoardDelegate sharedBoard] addSubview:tempConnector positioned:NSWindowBelow relativeTo:nil];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];

    NSPoint thisLocation = [self convertPoint:[self bounds].origin toView:[VJXBoardDelegate sharedBoard]];

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
        tempConnector.direction = kSouthWestDirection;
    }
    else if ((locationInWindow.y < thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        tempConnector.direction = kSouthEastDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x < thisLocation.x)) {
        tempConnector.direction = kNorthWestDirection;
    }
    else if ((locationInWindow.y > thisLocation.y) && (locationInWindow.x > thisLocation.x)) {
        tempConnector.direction = kNorthEastDirection;
    }

    NSRect frame = NSMakeRect(minX, minY, width, height);
    [tempConnector setFrame:frame];
    [self.superview setNeedsDisplay:YES];

}

- (void)mouseUp:(NSEvent *)theEvent
{
    NSPoint locationInWindow = [theEvent locationInWindow];
    
    NSView *aView = [[VJXBoardDelegate sharedBoard] hitTest:locationInWindow];
    
    if ([aView isKindOfClass:[VJXBoardEntityPin class]]) {
        
        VJXBoardEntityPin *otherPin = (VJXBoardEntityPin *)aView;
        
        NSLog(@"this Pin: %@, other Pin: %@", self.pin.name, otherPin.pin.name);
        
        [otherPin.pin connectToPin:self.pin];

        [tempConnector setOrigin:self];
        [tempConnector setDestination:otherPin];

        [otherPin addConnector:self.tempConnector];
        [self addConnector:self.tempConnector];
        
        self.tempConnector = nil;
    }
    else {
        [tempConnector removeFromSuperview];
        self.tempConnector = nil;
    }
}

- (NSPoint)pointAtCenter
{
    NSPoint origin = [self frame].origin;
    NSSize size = [self frame].size;
    NSPoint center = NSMakePoint(origin.x + (size.width / 2), origin.y + (size.height / 2));
    return center;
}

- (void)updateAllConnectorsFrames
{
    [connectors makeObjectsPerformSelector:@selector(recalculateFrame)];
}

- (BOOL)multiple
{
    return [[self pin] multiple];
}

- (void)addConnector:(VJXBoardEntityConnector *)theConnector
{
    [connectors addObject:theConnector];
}


@end
