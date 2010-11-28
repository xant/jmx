//
//  JMXBoardViewController.m
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXBoardViewController.h"
#import "JMXRunLoop.h"
#import "JMXEntitiesController.h"

#include <math.h>


@interface JMXBoardViewController ()

- (JMXBoardView *)boardView;
- (void)boardWasModified:(NSNotification *)aNotification;
- (void)anEntityWasCreated:(NSNotification *)aNotification;

- (BOOL)mouseDownWithPinLayer:(JMXPinLayer *)aPinLayer andEvent:(NSEvent *)theEvent;
- (BOOL)mouseDownWithConnectorLayer:(JMXConnectorLayer *)aConnectorLayer andEvent:(NSEvent *)theEvent;
- (BOOL)mouseDownWithEntityLayer:(JMXEntityLayer *)anEntityLayer andEvent:(NSEvent *)theEvent;

- (void)setHoveredPinLayer:(JMXPinLayer *)aPinLayer;

@end

@implementation JMXBoardViewController

@synthesize document;
@synthesize selectedLayer;
@synthesize selectedConnectorLayer;
@synthesize entities;
@synthesize entitiesController;

#pragma mark -
#pragma mark Private

- (JMXBoardView *)boardView
{
    return (JMXBoardView *)[self view];
}

#pragma mark -

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(anEntityWasCreated:)
                                                 name:@"JMXBoardEntityWasCreated"
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boardWasModified:)
                                                 name:@"JMXEntityInputPinAdded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boardWasModified:)
                                                 name:@"JMXEntityInputPinRemoved"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boardWasModified:)
                                                 name:@"JMXEntityOutputPinAdded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(boardWasModified:)
                                                 name:@"JMXEntityOutputPinRemoved"
                                               object:nil];

    selected = [[NSMutableArray alloc] init];
    entities = [[NSMutableArray alloc] init];
    [entitiesController setContent:entities];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [selected release];
    [entities release];
    [super dealloc];
}


#pragma mark -
#pragma mark NSViewController

- (void)setView:(NSView *)aView
{
    [super setView:aView];
    if (aView) {
        [(JMXBoardView *)aView setDocument:[self document]];
        [aView setNextResponder:self];
    }

}

#pragma mark -
#pragma mark Mouse events

- (BOOL)mouseDownWithEntityLayer:(JMXEntityLayer *)anEntityLayer andEvent:(NSEvent *)theEvent
{
    if (anEntityLayer != nil) {
        NSMutableArray *selectedObjects = [[entitiesController selectedObjects] mutableCopy];
        if ([theEvent modifierFlags] & NSCommandKeyMask) {
            if ([selectedObjects containsObject:anEntityLayer]) {
                [selectedObjects removeObject:anEntityLayer];
                [entitiesController setSelectedObjects:selectedObjects];
            }
            else {
                [selectedObjects addObject:anEntityLayer];
                [entitiesController setSelectedObjects:selectedObjects];
            }
        }
        else {
            [entitiesController setSelectedObjects:[NSArray arrayWithObject:anEntityLayer]];
        }
    }
    else {
        [entitiesController setSelectedObjects:[NSArray array]];
        [self setSelectedConnectorLayer:nil];
    }
    
    return YES;
}

- (BOOL)mouseDownWithPinLayer:(JMXPinLayer *)aPinLayer andEvent:(NSEvent *)theEvent
{
    if (aPinLayer != nil) {
        CGPoint pointAtCenter = [self.boardView.layer convertPoint:[aPinLayer pointAtCenter] fromLayer:aPinLayer];
        fakeConnectorLayer = [[[JMXConnectorLayer alloc] initWithOriginPinLayer:aPinLayer] autorelease];
        [aPinLayer addConnector:fakeConnectorLayer];
        fakeConnectorLayer.initialPosition = pointAtCenter;
        fakeConnectorLayer.boardView = self.boardView;
        [self.boardView.layer addSublayer:fakeConnectorLayer];
        [entitiesController unselectAll];
        return YES;
    }
    return NO;
}

- (BOOL)mouseDownWithConnectorLayer:(JMXConnectorLayer *)aConnectorLayer andEvent:(NSEvent *)theEvent
{
    if (aConnectorLayer != nil) {
        [self setSelectedConnectorLayer:aConnectorLayer];
        return YES;
    }
    return NO;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    lastDragLocation = [theEvent locationInWindow];

    JMXPinLayer *aPinLayer = [self.boardView pinLayerAtPoint:lastDragLocation];
    
    if ([self mouseDownWithPinLayer:aPinLayer andEvent:theEvent])
        return;
    
    JMXConnectorLayer *aConnectorLayer = [self.boardView connectorLayerAtPoint:lastDragLocation];
    
    if ([self mouseDownWithConnectorLayer:aConnectorLayer andEvent:theEvent])
        return;
    
    JMXEntityLayer *anEntityLayer = [self.boardView entityLayerAtPoint:lastDragLocation];
    
    if ([self mouseDownWithEntityLayer:anEntityLayer andEvent:theEvent])
        return;
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSArray *selectedLayers = [entitiesController selectedObjects];

    NSPoint locationInWindow = [theEvent locationInWindow];
    NSPoint offset = NSMakePoint(locationInWindow.x - lastDragLocation.x, locationInWindow.y - lastDragLocation.y);
    lastDragLocation = locationInWindow;

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];

    // If we have several layers selected, we want to drag them in the board.
    if ([selectedLayers count] > 0) {
        [selectedLayers makeObjectsPerformSelector:@selector(moveToPointWithOffset:) withObject:[NSValue valueWithPoint:offset]];
    }

    // If we have a fake connector layer, then we want to update its coordinates.
    if (fakeConnectorLayer) {
        NSPoint currentLocation = [self.boardView convertPoint:[theEvent locationInWindow] fromView:nil];
        [fakeConnectorLayer recalculateFrameWithPoint:*(CGPoint*)&currentLocation];
    }
    
    JMXPinLayer *aPinLayer = [self.boardView pinLayerAtPoint:lastDragLocation];

    if ([fakeConnectorLayer originCanConnectTo:aPinLayer]) {
        [self setHoveredPinLayer:aPinLayer];
        [fakeConnectorLayer recalculateFrameWithPoint:[self.boardView.layer convertPoint:[aPinLayer pointAtCenter] fromLayer:aPinLayer]];
    }
    else 
        [self setHoveredPinLayer:nil];
        

    [CATransaction commit];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    lastDragLocation = NSZeroPoint;

    if (fakeConnectorLayer) {
        if (hoveredPinLayer && [fakeConnectorLayer.originPinLayer.pin canConnectToPin:hoveredPinLayer.pin]) {
            [fakeConnectorLayer.originPinLayer.pin connectToPin:hoveredPinLayer.pin];
            fakeConnectorLayer.destinationPinLayer = hoveredPinLayer;
            [hoveredPinLayer addConnector:fakeConnectorLayer];
        }
        else
            [fakeConnectorLayer removeFromSuperlayer];
        fakeConnectorLayer = nil;
    }

    [self setHoveredPinLayer:nil];
}

#pragma mark -
#pragma mark Getters and setters

- (void)setHoveredPinLayer:(JMXPinLayer *)aPinLayer
{
    [hoveredPinLayer unfocus];
    hoveredPinLayer = aPinLayer;
    [hoveredPinLayer focus];
}

- (void)setSelectedLayer:(JMXEntityLayer *)aLayer
{
    if (aLayer == selectedLayer)
        return;

    if (aLayer != nil)
        [aLayer select];

    if (selectedLayer != nil)
        [selectedLayer unselect];

    selectedLayer = aLayer;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasSelected" object:self.selectedLayer];

    if (!selectedLayer)
        return;

    aLayer.zPosition = [self.boardView maxZPosition];
}

- (void)setSelectedConnectorLayer:(JMXConnectorLayer *)aConnectorLayer
{
    if (aConnectorLayer == selectedConnectorLayer)
        return;

    if (aConnectorLayer != nil)
        [aConnectorLayer select];

    if (selectedConnectorLayer != nil)
        [selectedConnectorLayer unselect];

    selectedConnectorLayer = aConnectorLayer;
}


#pragma mark -
#pragma mark IBActions

- (IBAction)removeSelectedEntity:(id)sender
{
    NSArray *selectedObjects = [entitiesController selectedObjects];
    
    if ([selectedObjects count]) {
        [selectedObjects makeObjectsPerformSelector:@selector(removeFromBoard)];
        [entitiesController removeObjects:selectedObjects];
    }

    if (selectedConnectorLayer) {
        [selectedConnectorLayer disconnect];
        self.selectedConnectorLayer = nil;
    }
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification
{
    JMXEntity *anEntity = [aNotification object];
    JMXEntityLayer *entityLayer = [[[JMXEntityLayer alloc] initWithEntity:anEntity board:[self boardView]] autorelease];

    NSValue *pointValue = [[aNotification userInfo] valueForKey:@"origin"];

    if (pointValue) {
        CGPoint p = [self.boardView translatePointToBoardLayer:[pointValue pointValue]];
        entityLayer.position = CGPointMake(ceilf(p.x), ceilf(p.y));
    }

    [entitiesController addObject:entityLayer];
    [entitiesController setSelectedObjects:[NSArray arrayWithObject:entityLayer]];
    [self.boardView.layer addSublayer:entityLayer];

    if ([anEntity conformsToProtocol:@protocol(JMXRunLoop)])
        [anEntity performSelector:@selector(start)];
}

- (void)boardWasModified:(NSNotification *)aNotification
{
    
}

@end
