//
//  JMXBoardViewController.m
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXBoardViewController.h"
#import "JMXRunLoop.h"


@interface JMXBoardViewController ()

- (JMXBoardView *)boardView;
- (void)anEntityWasCreated:(NSNotification *)aNotification;
- (void)boardWasModified:(NSNotification *)aNotification;

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

- (void)mouseDown:(NSEvent *)theEvent
{
    lastDragLocation = [theEvent locationInWindow];

    JMXEntityLayer *anEntityLayer = [self.boardView entityLayerAtPoint:lastDragLocation];

    if (anEntityLayer) {
        NSMutableArray *selectedEntities = [[entitiesController selectedObjects] mutableCopy];
        [selectedEntities addObject:anEntityLayer];
        [selectedEntities makeObjectsPerformSelector:@selector(select)];
        [entitiesController setSelectedObjects:selectedEntities];

        if ([selectedEntities count] == 1)
            [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasSelected" object:anEntityLayer];
    }
    else {
        [[entitiesController selectedObjects] makeObjectsPerformSelector:@selector(unselect)];
        [entitiesController setSelectedObjects:[NSArray array]];
    }


//    JMXPinLayer *aPinLayer = [self.boardView pinLayerAtPoint:locationInWindow];
//    JMXConnectorLayer *aConnectorLayer = [self.boardView connectorLayerAtPoint:locationInWindow];

//    self.selectedLayer = nil;
//    self.selectedConnectorLayer = nil;
//
//    if (anEntityLayer) {
//        [entitiesController setSelectedObjects:[NSArray arrayWithObject:anEntityLayer]];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"JMXBoardEntityWasSelected" object:anEntityLayer];
//    }
//    else if (aPinLayer) {
//        CGPoint pointAtCenter = [self.boardView.layer convertPoint:[aPinLayer pointAtCenter] fromLayer:aPinLayer];
//        fakeConnectorLayer = [[[JMXConnectorLayer alloc] initWithOriginPinLayer:aPinLayer] autorelease];
//        [aPinLayer addConnector:fakeConnectorLayer];
//        fakeConnectorLayer.initialPosition = pointAtCenter;
//        fakeConnectorLayer.boardView = self.boardView;
//        [self.boardView.layer addSublayer:fakeConnectorLayer];
//    }
//    else if (aConnectorLayer) {
//        self.selectedConnectorLayer = aConnectorLayer;
//    }
//    else {
//        [entitiesController setSelectedObjects:[NSArray array]];
//    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSArray *selectedLayers = [entitiesController selectedObjects];

    NSPoint locationInWindow = [theEvent locationInWindow];
    NSPoint offset = NSMakePoint(locationInWindow.x - lastDragLocation.x, locationInWindow.y - lastDragLocation.y);
    lastDragLocation = locationInWindow;

    if ([selectedLayers count] > 0) {
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
        [selectedLayers makeObjectsPerformSelector:@selector(moveToPointWithOffset:) withObject:[NSValue valueWithPoint:offset]];
        [CATransaction commit];
    }

//    if (fakeConnectorLayer) {
//        NSPoint currentLocation = [self.boardView convertPoint:[theEvent locationInWindow] fromView:nil];
//        [fakeConnectorLayer recalculateFrameWithPoint:*(CGPoint*)&currentLocation];
//        [fakeConnectorLayer setNeedsDisplay];
//    }
//
//    else if (selectedLayer) {
//        selectedLayer.position = [self.boardView translatePointToBoardLayer:[theEvent locationInWindow]];
//        [selectedLayer updateConnectors];
//    }
//    JMXPinLayer *aPinLayer = [self.boardView pinLayerAtPoint:[theEvent locationInWindow]];
//    if (aPinLayer && [fakeConnectorLayer.originPinLayer.pin canConnectToPin:aPinLayer.pin]) {
//        [hoveredPinLayer unfocus];
//        hoveredPinLayer = aPinLayer;
//        [hoveredPinLayer focus];
//    } else {
//        [hoveredPinLayer unfocus];
//        hoveredPinLayer = nil;
//    }
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

    [hoveredPinLayer unfocus];
    hoveredPinLayer = nil;
}

#pragma mark -
#pragma mark Getters and setters

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
    JMXEntityLayer *layer = selectedLayer;
    if (layer) {
        [self setSelectedLayer:nil];
        [layer removeFromSuperlayer];
        [entities removeObject:layer];
    }

    if (selectedConnectorLayer) {
        [selectedConnectorLayer.originPinLayer.pin disconnectFromPin:selectedConnectorLayer.destinationPinLayer.pin];
        self.selectedConnectorLayer = nil;
    }
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification
{
    JMXEntity *anEntity = [aNotification object];
    JMXEntityLayer *entityLayer = [[[JMXEntityLayer alloc] initWithEntity:anEntity board:self.boardView] autorelease];

    NSValue *pointValue = [[aNotification userInfo] valueForKey:@"origin"];

    if (pointValue)
        entityLayer.position = [self.boardView translatePointToBoardLayer:[pointValue pointValue]];

    [entitiesController addObject:entityLayer];
    [entitiesController setSelectedObjects:[NSArray arrayWithObject:entityLayer]];
    [self.boardView.layer addSublayer:entityLayer];

    // self.selectedLayer = theEntity;

    if ([anEntity conformsToProtocol:@protocol(JMXRunLoop)])
        [anEntity performSelector:@selector(start)];
}

- (void)boardWasModified:(NSNotification *)aNotification
{
    [self.boardView.layer setNeedsLayout];
}
@end
