//
//  VJXBoardComponentOutlet.m
//  GraphRep
//
//  Created by Igor Sutton on 8/26/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import "VJXBoardEntityPin.h"

@implementation VJXBoardEntityPin

@synthesize pin, connector;

- (id)initWithFrame:(NSRect)frame {
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

- (void)drawRect:(NSRect)dirtyRect {
    NSBezierPath *thePath = nil;

    [[NSColor redColor] set];
    thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithOvalInRect:[self bounds]];
    [thePath fill];
    [thePath release];

//    VJXBoardEntityPin *origin = [connector origin];
//    VJXBoardEntityPin *destination = [connector destination];

//    NSPoint originPoint = [connector.superview.superview convertPoint:origin.frame.origin fromView:origin];
//    NSPoint destinationPoint = [connector.superview.superview convertPoint:destination.frame.origin fromView:destination];

//    float x = MIN(originPoint.x, destinationPoint.x);
//    float y = MIN(originPoint.y, destinationPoint.y);
//    float w = abs(originPoint.x - destinationPoint.x);
//    float h = abs(originPoint.y - destinationPoint.y);
//
//    NSLog(@"%f:%f:%f:%f", x, y, w, h);

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
    }
}

#define SOUTHWEST 0
#define SOUTHEAST 1
#define NORTHWEST 2
#define NORTHEAST 3



- (void)mouseDragged:(NSEvent *)theEvent
{
    if (!connector) {
        connector = [[VJXBoardEntityConnector alloc] init];
        [connector setOrigin:self];
        [self.superview.superview addSubview:connector positioned:0 relativeTo:nil];
    }

    NSPoint locationInWindow = [theEvent locationInWindow];
    
    NSView *aView = [self.superview.superview hitTest:locationInWindow];
    
    NSLog(@"aView: %@", aView);
    
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

//- (void)mouseUp:(NSEvent *)theEvent
//{
//    NSPoint currentLocation = [theEvent locationInWindow];
//    NSView *view = [self.superview.superview hitTest:currentLocation];
//    //NSLog(@"View: %@", view);
//
//    NSLog(@"Pin Name: %@", self.pin.name);
//    
//    if ((!view) || (![view isKindOfClass:[VJXBoardEntityPin class]])) {
////        [connector removeFromSuperview];
////        [connector release];
////        connector = nil;
//        return;
//    }
//
////    VJXBoardEntityPin *pin = (VJXBoardEntityPin *)view;
////    [pin setConnector:connector];
////    [connector setDestination:pin];
//}

@end
