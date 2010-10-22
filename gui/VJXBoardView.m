//
//  VJXBoard.m
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

#import "VJXBoardView.h"
#import "VJXBoardLayer.h"
#import "VJXQtVideoLayer.h"
#import "VJXAudioFileLayer.h"
#import "VJXFileRead.h"

@implementation VJXBoardView

@synthesize selectedLayer;

#pragma mark -
#pragma mark Initialization

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        selected = [[NSMutableArray alloc] init];
        entities = [[NSMutableArray alloc] init];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType,NSFilenamesPboardType,VJXLibraryTableViewDataType,nil]];
    }
    return self;
}

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasCreated:) name:@"VJXBoardEntityWasCreated" object:nil];

    VJXBoardLayer *boardLayer = [[[VJXBoardLayer alloc] init] autorelease];
    self.layer = boardLayer;
    [self setWantsLayer:YES];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [selected release];
    [entities release];
    [super dealloc];
}

#pragma mark -
#pragma mark Getters and setters

- (void)setSelectedLayer:(VJXEntityLayer *)aLayer
{
    if (aLayer == selectedLayer)
        return;

    if (aLayer != nil)
        [aLayer select];

    if (selectedLayer != nil)
        [selectedLayer unselect];

    selectedLayer = aLayer;

    [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasSelected" object:self.selectedLayer];

    if (!selectedLayer)
        return;

    aLayer.zPosition = [self maxZPosition];
}

#pragma mark -
#pragma mark Dragging operations

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES; //[NSURL URLFromPasteboard: [sender draggingPasteboard]];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	/*------------------------------------------------------
     method that should handle the drop data
     --------------------------------------------------------*/

	// draggingSource returns nil if another application started the drag
	// operation. We'll assume all drags will either start from Finder or from
	// our library window.
    if ([sender draggingSource] == nil) {
        NSURL* fileURL;

        //if the drag comes from a file, set the window title to the filename
        fileURL=[NSURL URLFromPasteboard: [sender draggingPasteboard]];
        NSString *fileName = [fileURL lastPathComponent];
        NSArray *components = [fileName componentsSeparatedByString:@"."];
        // TODO - GENERALIZE
        if ([[VJXQtVideoLayer supportedFileTypes] containsObject:[components lastObject]]) {
            VJXQtVideoLayer *entity = [[VJXQtVideoLayer alloc] init];
            if (fileName && [entity conformsToProtocol:@protocol(VJXFileRead)]) {
                [entity performSelector:@selector(open:) withObject:[fileURL absoluteString]];
            }
            [entity start];
            [document.entities addObject:entity];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasCreated" object:entity];

            [entity release];
        } else if ([[VJXAudioFileLayer supportedFileTypes] containsObject:[components lastObject]]) {
            VJXAudioFileLayer *entity = [[VJXAudioFileLayer alloc] init];
            if (fileName && [entity conformsToProtocol:@protocol(VJXFileRead)]) {
                [entity performSelector:@selector(open:) withObject:[fileURL absoluteString]];
            }
            [entity start];

            [document.entities addObject:entity];

            [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasCreated" object:entity];

            [entity release];
        }
    }
	else {
		NSPasteboard *pboard = [sender draggingPasteboard];
		NSData *data = [pboard dataForType:VJXLibraryTableViewDataType];
		NSString *className = [NSKeyedUnarchiver unarchiveObjectWithData:data];
        [document createEntityWithClass:NSClassFromString(className) atPoint:[sender draggingLocation]];
	}

    return YES;
}

#pragma mark -
#pragma mark Mouse events

- (void)mouseDown:(NSEvent *)theEvent
{
    self.selectedLayer = [self entityLayerAtPoint:[theEvent locationInWindow]];

    if (!selectedLayer) {
        // Should create a selection layer on top of everything.
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.selectedLayer.position = [self translatePointToBoardLayer:[theEvent locationInWindow]];
    [CATransaction commit];
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification
{
    VJXEntity *anEntity = [aNotification object];
    VJXEntityLayer *entityLayer = [[[VJXEntityLayer alloc] initWithEntity:anEntity board:self] autorelease];

    NSValue *pointValue = [[aNotification userInfo] valueForKey:@"origin"];

    if (pointValue)
        entityLayer.position = [self translatePointToBoardLayer:[pointValue pointValue]];

    [self addToBoard:entityLayer];

    if ([anEntity conformsToProtocol:@protocol(VJXRunLoop)])
        [anEntity performSelector:@selector(start)];
}

#pragma mark -
#pragma mark Helpers

- (void)addToBoard:(VJXEntityLayer *)theEntity
{
    [self.layer addSublayer:theEntity];
    [entities addObject:theEntity];
    self.selectedLayer = theEntity;
}

- (CGPoint)translatePointToBoardLayer:(NSPoint)aPoint
{
    NSPoint localPoint = [self convertPoint:aPoint fromView:nil];
    NSPoint rootPoint = [self convertPointToBase:localPoint];
    CGPoint translatedPoint = NSPointToCGPoint(rootPoint);
    return translatedPoint;
}

- (VJXEntityLayer *)entityLayerAtPoint:(NSPoint)aPoint
{
    CALayer *aLayer = [self.layer hitTest:[self translatePointToBoardLayer:aPoint]];

    if ([aLayer isKindOfClass:[VJXEntityLayer class]])
        return (VJXEntityLayer *)aLayer;

    return nil;
}

- (CGFloat)maxZPosition
{
    CGFloat zPosition = ((CALayer *)[[self.layer sublayers] objectAtIndex:0]).zPosition;

    for (CALayer *l in entities) {
        if (l.zPosition >= zPosition)
            zPosition = l.zPosition + 0.1f;
    }

    return zPosition;
}

@end
