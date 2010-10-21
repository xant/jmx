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
#import "VJXQtVideoLayer.h"
#import "VJXAudioFileLayer.h"
#import "VJXFileRead.h"

@implementation VJXBoardView

@synthesize currentSelection;

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        selected = [[NSMutableArray alloc] init];
        entities = [[NSMutableArray alloc] init];
		[self registerForDraggedTypes:[NSArray arrayWithObjects:NSURLPboardType,NSFilenamesPboardType,VJXLibraryTableViewDataType,nil]];
        [self toggleSelected:nil multiple:NO];
    }
    return self;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
    return NSDragOperationCopy;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
    return YES;//[NSURL URLFromPasteboard: [sender draggingPasteboard]];
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

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasCreated:) name:@"VJXBoardEntityWasCreated" object:nil];
    [self setNeedsDisplay:YES];
}

- (BOOL)isFlipped
{
    return YES;
}

- (void)viewWillDraw
{
    // We're calculating the biggest rect that can hold all the entities
    // currently living in the board, and setting the board's frame to that
    // rect. We should also keep a reference to the minimum size we want the
    // board to have, and if the rect is smaller than that resize to the
    // default.

    [entities makeObjectsPerformSelector:@selector(setNeedsDisplay)];

    float maxX = NSMaxX(self.frame);
    float maxY = NSMaxY(self.frame);

    for (VJXBoardEntity *e in entities) {
        [self addSubview:e];

        if (NSMaxX(e.frame) > maxX)
            maxX = NSMaxX(e.frame);

        if (NSMaxY(e.frame) > maxY)
            maxY = NSMaxY(e.frame);
    }

    NSRect newFrameRect = NSMakeRect(0.0, 0.0, maxX, maxY);
    [self setFrame:newFrameRect];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [selected release];
    [entities release];
    [currentSelection release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect {
    [[NSColor whiteColor] set];
    NSBezierPath *thePath = [[NSBezierPath alloc] init];
    [thePath appendBezierPathWithRect:dirtyRect];
    [thePath fill];
    [thePath release];
}


- (void)addToBoard:(VJXBoardEntity *)theEntity
{
    [self addSubview:theEntity];
    [entities addObject:theEntity];

    // Put focus on the created entity.
    [self toggleSelected:theEntity multiple:NO];
}

- (void)toggleSelected:(id)theEntity multiple:(BOOL)isMultiple
{
    if ([theEntity isKindOfClass:[VJXBoardEntity class]] ||
        [theEntity isKindOfClass:[VJXBoardEntityConnector class]]) {
        // Add some point, we'll be using a NSArrayController to have references of
        // all entities we have on the board, so the entity selection will be done
        // thru it instead of this code. Using NSArrayController for that will be
        // nice because we can use KVC in IB to create the Inspector palettes.

        // Unselect all entities, and toggle only the one we selected.
        if (!isMultiple) {
            [entities makeObjectsPerformSelector:@selector(unselect)];
            [selected removeAllObjects];
        }


        // Move the selected entity to the end of the subviews array, making it move
        // to the top of the view hierarchy.
        if ([entities count] >= 1) {
            NSMutableArray *subviews = [[self subviews] mutableCopy];
            [subviews removeObjectAtIndex:[subviews indexOfObject:theEntity]];
            [subviews addObject:theEntity];
            [self setSubviews:subviews];
            [subviews release];
        }

        [theEntity toggleSelected];

        // Add or remove the entity based on its current selected status.
        if ([theEntity isKindOfClass:[VJXBoardEntity class]]) {
            VJXBoardEntity *e = theEntity;
            if (e.selected) {
                [selected addObject:e];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasSelected" object:theEntity];
            }
            else
                [selected removeObject:e];
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    lastDragLocation = [self convertPoint:[theEvent locationInWindow] fromView:nil];

    // Unselect all the selected entities if the user click on the board.
    [entities makeObjectsPerformSelector:@selector(unselect)];
    [selected removeAllObjects];
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    NSPoint thisLocation = [theEvent locationInWindow];

    // Create a view VJXBoardSelection and place it in the top of the view
    // hierarchy if it already doesn't exist.
    if (!currentSelection) {
        self.currentSelection = [[[VJXBoardSelection alloc] init] autorelease];
        [self addSubview:currentSelection positioned:NSWindowAbove relativeTo:nil];
    }

    thisLocation = [self convertPoint:thisLocation fromView:nil];

    // Calculate the frame based on the window's coordinates and set the rect
    // as the current selection frame.
    [currentSelection setFrame:NSMakeRect(MIN(thisLocation.x, lastDragLocation.x),
                                          MIN(thisLocation.y, lastDragLocation.y),
                                          abs(thisLocation.x - lastDragLocation.x),
                                          abs(thisLocation.y - lastDragLocation.y))];

    for (VJXBoardEntity *entity in entities) {
        // Unselect the entity. We'll have all the entities unselected as net
        // result of this operation, if the entity isn't inside the current
        // selection rect.
        [entity setSelected:[entity inRect:[currentSelection frame]]];
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    [currentSelection removeFromSuperview];
    self.currentSelection = nil;
}

- (void)shiftSelectedToLocation:(NSPoint)aLocation;
{
    for (VJXBoardEntity *e in selected) {
        [e shiftOffsetToLocation:aLocation];
    }
}

- (BOOL)isMultipleSelection
{
    return [selected count] > 1;
}

- (IBAction)removeSelected:(id)sender
{
    for (NSUInteger i = 0; i < [entities count]; i++) {
        VJXBoardEntity *e = [entities objectAtIndex:i];
        if (e.selected) {

            // Remove the entity from our internal entities array.
            [entities removeObject:e];

            // And remove also from our selectedEntities array...
            [selected removeObject:e];

            // Remove the entity from the superview.
            //
            // It seems removeFromSuperview autoreleases the view, instead of
            // releasing it at the time we remove it, so retainCount won't be
            // updated until the end of the run loop.
            [e removeFromSuperview];

            // Notify observers we removed the entity.
            [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasRemoved" object:e.entity];

            // Decrease counter because we removed the element.
            i--;
        }
    }
}

- (void)notifyChangesToDocument
{
    for (VJXBoardEntity *e in entities) {
        NSPoint origin = [e frame].origin;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"VJXBoardEntityWasMoved" object:e userInfo:[NSDictionary dictionaryWithObject:NSStringFromPoint(origin) forKey:@"origin"]];
    }

}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasCreated:(NSNotification *)aNotification
{
    VJXEntity *anEntity = [aNotification object];
    VJXBoardEntity *boardEntity = [[VJXBoardEntity alloc] initWithEntity:anEntity board:self];
    NSValue *origin = [[aNotification userInfo] objectForKey:@"origin"];
    NSSize boardEntitySize = [boardEntity frame].size;

    // If origin is provided, then we calculate the real origin based on the
    // entity board's geometry.
    if (origin) {
        NSPoint realOrigin = [origin pointValue];
        realOrigin.x -= (boardEntitySize.width / 2);
        realOrigin.y -= (boardEntitySize.height / 2);
        [boardEntity setFrameOrigin:realOrigin];
    }

    [self addToBoard:boardEntity];

    // XXX - perhaps we should let the user start entities esplicitly
    //       (and we need to provide seek controls as well)
    if ([anEntity conformsToProtocol:@protocol(VJXRunLoop)])
        [anEntity performSelector:@selector(start)];

    [boardEntity release];
}

@end
