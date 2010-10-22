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

@synthesize currentSelection;
@synthesize selectedLayer;

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
    [currentSelection release];
    [super dealloc];
}

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
        NSPoint draggingLocation = [self convertPoint:[sender draggingLocation] fromView:nil];
        [document createEntityWithClass:NSClassFromString(className) atPoint:draggingLocation];
	}

    return YES;
}

- (void)addToBoard:(VJXEntityLayer *)theEntity
{
    [self.layer addSublayer:theEntity];
    [entities addObject:theEntity];
    self.selectedLayer = theEntity;
}

- (void)setSelectedLayer:(VJXEntityLayer *)aLayer
{
    if (aLayer == selectedLayer)
        return;

    if (aLayer != nil)
        [aLayer select];

    if (selectedLayer != nil)
        [selectedLayer unselect];

    selectedLayer = aLayer;

    if (!selectedLayer)
        return;

    CGFloat zPosition = aLayer.zPosition;

    for (CALayer *l in entities) {
        if (l.zPosition >= zPosition)
            zPosition = l.zPosition + 0.1f;
    }

    aLayer.zPosition = zPosition;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint rootPoint = [self convertPointToBase:localPoint];
    CGPoint locationInWindow = NSPointToCGPoint(rootPoint);
    CALayer *aLayer = [self.layer hitTest:locationInWindow];

    if ([aLayer isKindOfClass:[VJXEntityLayer class]]) {
        VJXEntityLayer *entityLayer = (VJXEntityLayer *)aLayer;
        self.selectedLayer = entityLayer;
    }
    else {
        self.selectedLayer = nil;
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint localPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    NSPoint rootPoint = [self convertPointToBase:localPoint];
    CGPoint newDragLocation = NSPointToCGPoint(rootPoint);

    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    self.selectedLayer.position = newDragLocation;
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
    VJXEntityLayer *boardEntity = [[VJXEntityLayer alloc] initWithEntity:anEntity board:self];
    [self addToBoard:boardEntity];

    if ([anEntity conformsToProtocol:@protocol(VJXRunLoop)])
        [anEntity performSelector:@selector(start)];

    [boardEntity release];
}

@end
