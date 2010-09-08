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

- (id)initWithPin:(VJXPin *)thePin andPoint:(NSPoint)thePoint
{
    NSRect frame = NSMakeRect(thePoint.x, thePoint.y, 18.0, 18.0);
    
    if ((self = [super initWithFrame:frame]) != nil) {
        self.connectors = [[NSMutableArray alloc] init];
        self.pin = thePin;        
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
    NSRect pinRect;
    pinRect = NSMakeRect([self bounds].origin.x, [self bounds].origin.y, [self bounds].size.height, [self bounds].size.height);
    [thePath appendBezierPathWithOvalInRect:pinRect];
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

    NSPoint thisLocation = [self convertPoint:[self pointAtCenter] toView:[VJXBoardDelegate sharedBoard]];

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
        
        if ([otherPin.connectors count] && !otherPin.pin.multiple) {
            // XXX - there are too many references around ...
            //       maintaining all these lists is far too complex
            //       and we don't really need all these circular refences
            //       since they can easily lead to leaks
            for (VJXBoardEntityConnector *connector in otherPin.connectors) {
                if (connector.origin == otherPin) {
                    [connector.destination.connectors removeObject:connector];
                } else {
                    [connector.origin.connectors removeObject:connector];
                }
                [connector removeFromSuperview];
            }
            [otherPin.connectors removeAllObjects];
        }

        [otherPin.pin connectToPin:self.pin];

        [tempConnector setOrigin:self];
        [tempConnector setDestination:otherPin];

        [otherPin addConnector:self.tempConnector];
        [self addConnector:self.tempConnector];
        
        [self updateAllConnectorsFrames];
        
        self.tempConnector = nil;
    }
    else {
        [tempConnector removeFromSuperview];
        self.tempConnector = nil;
    }
}

- (NSPoint)pointAtCenter
{
    NSPoint origin = [self bounds].origin;
    NSSize size = [self bounds].size;
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
