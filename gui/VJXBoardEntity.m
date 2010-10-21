//
//  VJXBoardComponent.m
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

#import "VJXBoardEntity.h"
#import "VJXBoardEntityPin.h"
#import "VJXBoardEntityOutlet.h"
#import "VJXEntityInspector.h"

@implementation VJXBoardEntity

@synthesize entity;
@synthesize label;
@synthesize selected;
@synthesize outlets;
@synthesize board;

- (void)initView
{
    [self setSubviews:[NSArray array]];
    NSUInteger maxNrPins = MAX([[self.entity inputPins] count], [[self.entity outputPins] count]);

    CGFloat pinSide = ENTITY_PIN_HEIGHT;
    CGFloat height = pinSide * maxNrPins * ENTITY_PIN_MINSPACING;
    CGFloat width = ENTITY_FRAME_WIDTH;

    NSTextField *labelView = [[[NSTextField alloc] init] autorelease];
    [labelView setTextColor:[NSColor whiteColor]];
    [labelView setStringValue:[self.entity description]];
    [labelView setBordered:NO];
    [labelView setEditable:YES];
    [labelView setFocusRingType:NSFocusRingTypeNone];
    [labelView setDelegate:self];
    [labelView setDrawsBackground:NO];
    [labelView setFont:[NSFont boldSystemFontOfSize:[NSFont smallSystemFontSize]]];
    [labelView sizeToFit];
    labelHeight = [labelView frame].size.height;
    NSRect frame = NSMakeRect([self frame].origin.x, [self frame].origin.y, width, height + labelHeight + ENTITY_LABEL_PADDING);
    NSRect labelFrame = [labelView frame];
    labelFrame.origin.x += ENTITY_LABEL_PADDING;
    labelFrame.origin.y = frame.size.height-labelHeight - ENTITY_LABEL_PADDING/2;
    labelFrame.size.width = width - ENTITY_LABEL_PADDING;
    [labelView setFrame:labelFrame];
    [self setFrame:frame];
    self.label = labelView;
    [self addSubview:self.label];

    NSRect bounds = [self bounds];
    bounds.size.height -= (labelHeight + ENTITY_LABEL_PADDING);
    bounds.origin.x += ENTITY_PIN_LEFT_PADDING;
    self.outlets = [NSMutableArray array];
    int i = 0;
    NSArray *pins = [self.entity inputPins];
    NSUInteger nrInputPins = [pins count];
    for (NSString *pinName in pins) {
        NSPoint origin = NSMakePoint(bounds.origin.x, (((bounds.size.height / nrInputPins) * i++) - (bounds.origin.y - (3.0))));
        VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[self.entity inputPinWithName:pinName]
                                                                        andPoint:origin
                                                                        isOutput:NO
                                                                          entity:self];
        [self addSubview:outlet];
        [self.outlets addObject:outlet];
        [outlet release];
    }
    pins = [self.entity outputPins];
    NSUInteger nrOutputPins = [pins count];
    i = 0;
    for (NSString *pinName in pins) {
        NSPoint origin = NSMakePoint(bounds.size.width - ENTITY_OUTLET_WIDTH ,
                                     (((bounds.size.height / nrOutputPins) * i++) - (bounds.origin.y - (3.0))));
        VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[self.entity outputPinWithName:pinName]
                                                                        andPoint:origin
                                                                        isOutput:YES
                                                                          entity:self];
        [self addSubview:outlet];
        [self.outlets addObject:outlet];
        [outlet release];
    }
}

- (void)inputPinAdded:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *pinName = [userInfo objectForKey:@"pinName"];
    NSRect frame = [self frame];
    CGFloat pinSide = ENTITY_PIN_HEIGHT;
    CGFloat height = pinSide * ([self.outlets count]+1) * ENTITY_PIN_MINSPACING;
    frame.size.height = height;
    [self setFrame:frame];
    NSRect bounds = [self bounds];
    bounds.size.height -= (labelHeight + ENTITY_LABEL_PADDING);
    bounds.origin.x += ENTITY_PIN_LEFT_PADDING;
    NSLog(@"%@", self.outlets);
    int i = 0;
    for (VJXBoardEntityOutlet *pinOutlet in self.outlets) {
        NSPoint origin = NSMakePoint(bounds.origin.x, (((bounds.size.height / [self.outlets count]+1) * i++) - (bounds.origin.y - (3.0))));
        NSRect pinFrame = [pinOutlet frame];
        pinFrame.origin = origin;
        [pinOutlet setFrame:frame];
    }

    NSPoint origin = NSMakePoint(bounds.origin.x, (((bounds.size.height / [self.outlets count]+1) * [self.outlets count]+1) - (bounds.origin.y - (3.0))));
    VJXBoardEntityOutlet *outlet = [[VJXBoardEntityOutlet alloc] initWithPin:[self.entity inputPinWithName:pinName]
                                                                    andPoint:origin
                                                                    isOutput:NO
                                                                      entity:self];
    [self addSubview:outlet];
    [self.outlets addObject:outlet];
    NSRect labelFrame = [self.label frame];
    labelFrame.origin.y = frame.size.height - labelHeight - ENTITY_LABEL_PADDING / 2;
    [self.label setFrame:labelFrame];
    [outlet release];
}

- (void)inputPinRemoved:(NSNotification *)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *pinName = [userInfo objectForKey:@"pinName"];
    VJXBoardEntityOutlet *toRemove = nil;
    for (VJXBoardEntityOutlet *outlet in self.outlets) {
        if (outlet.pin.pin.name == pinName) {
            toRemove = outlet;
            break;
        }
    }
    if (toRemove)
        [self.outlets removeObject:toRemove];
    [toRemove removeFromSuperview];
}

- (void)outputPinAdded:(NSNotification *)notification
{
}

- (void)outputPinRemoved:(NSNotification *)notification
{
}


- (id)initWithEntity:(VJXEntity *)anEntity
{
    return [self initWithEntity:anEntity board:nil];
}

- (id)initWithEntity:(VJXEntity *)anEntity board:(VJXBoardView *)aBoard
{
    self = [super init];

    if (self = [super initWithFrame:NSMakeRect(10.0, 10.0, 0, 0)]) {
        self.board = aBoard;
        self.entity = anEntity;
        self.entity.name = [anEntity description];
        self.selected = NO;
        //self.outlets = [NSMutableArray array]; // XXX - actually done in initView
        [self initView];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinAdded:)
                                                     name:@"VJXEntityInputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(inputPinRemoved:)
                                                     name:@"VJXEntityInputPinRemoved"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinAdded:)
                                                     name:@"VJXEntityOutputPinAdded"
                                                   object:self.entity];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(outputPinRemoved:)
                                                     name:@"VJXEntityOutputPinRemoved"
                                                   object:self.entity];

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityInputPinAdded" object:entity];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityInputPinRemoved" object:entity];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityOutputPinAdded" object:entity];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"VJXEntityOutputPinRemoved" object:entity];
    if ([entity respondsToSelector:@selector(stop)])
        [entity performSelector:@selector(stop)];
    [entity release];

    [label release];
    [outlets release];
    [super dealloc];
}

- (void)setNeedsDisplay
{
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {

    NSShadow *dropShadow = [[[NSShadow alloc] init] autorelease];

    [dropShadow setShadowColor:[NSColor blackColor]];
    [dropShadow setShadowBlurRadius:2.5];
    [dropShadow setShadowOffset:NSMakeSize(2.0, -2.0)];

    [dropShadow set];

    NSBezierPath *thePath = nil;

    NSRect rect = NSOffsetRect([self bounds], 4.0, 4.0);
    rect.size.width -= 8.0;
    rect.size.height -= 8.0;

    thePath = [[NSBezierPath alloc] init];

    [[NSColor colorWithDeviceRed:0.0 green:0.0 blue:0.0 alpha:0.5] setFill];

    if (self.selected)
        [[NSColor yellowColor] setStroke];
    else
        [[NSColor blackColor] setStroke];

    NSAffineTransform *transform = [[[NSAffineTransform alloc] init] autorelease];
    [transform translateXBy:0.5 yBy:0.5];
    [thePath appendBezierPathWithRoundedRect:rect xRadius:4.0 yRadius:4.0];
    [thePath transformUsingAffineTransform:transform];
    [thePath fill];
    [thePath stroke];
    [thePath release];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    // Here we keep track of our initial location, so when mouseDragged: message
    // is called it knows the last drag location.
    lastDragLocation = [theEvent locationInWindow];

    // If we have the Command key pressed, we assume the user wants to select
    // several entities so we add the entity to the selection. If we have other
    // entities selected (more than one) we don't do anything since we assume
    // the user want to move the selected entities. If we don't have several
    // entities selected, we unfocus the current selection and focus the
    // one clicked.
    BOOL isMultiple = [theEvent modifierFlags] & NSCommandKeyMask ? YES : NO;
    if (isMultiple) {
        [board toggleSelected:self multiple:YES];
    }
    else {
        if (![board isMultipleSelection]) {
            [board toggleSelected:self multiple:NO];
        }
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    // Calculate the new location based on the last drag location and the
    // location, then ask the board to shift all the selected elements to the
    // new point.
    NSPoint newDragLocation = [theEvent locationInWindow];
    NSPoint newLocationOffset = NSMakePoint((-lastDragLocation.x + newDragLocation.x), (-lastDragLocation.y + newDragLocation.y));
    if (newDragLocation.y > 0 && newDragLocation.x > 0) {

        // We need to invert the y axis ourselves.
        newLocationOffset.y = -newLocationOffset.y;

        [board shiftSelectedToLocation:newLocationOffset];
        lastDragLocation = newDragLocation;
    }
}

- (void)mouseUp:(NSEvent *)theEvent
{
    // Cleanup last drag location.
    lastDragLocation = NSZeroPoint;
    [board notifyChangesToDocument];
}

- (void)setSelected:(BOOL)isSelected
{
    // Whenever the selected status is changed, we need to redraw the entity.
    if (selected != isSelected)
        [self setNeedsDisplay:YES];

    selected = isSelected;
}

- (void)toggleSelected
{
    self.selected = !self.selected;
}

- (NSString *)description
{
    return [self.entity description];
}

- (BOOL)inRect:(NSRect)rect
{
    return NSIntersectsRect(rect, [self frame]);
}

- (void)unselect
{
    [self setSelected:NO];
}

- (void)shiftOffsetToLocation:(NSPoint)aLocation
{
    NSRect thisFrame = NSOffsetRect([self frame], aLocation.x, aLocation.y);
    if (thisFrame.origin.x < 0) thisFrame.origin.x = 0.0;
    if (thisFrame.origin.y < 0) thisFrame.origin.y = 0.0;
    [self setFrame:thisFrame];
    [outlets makeObjectsPerformSelector:@selector(updateAllConnectorsFrames)];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor
{
    entity.name = [fieldEditor string];
    return YES;
}

- (id)copyWithZone:(NSZone *)aZone
{
    return [self retain];
}


id controlForVJXPinType(VJXPinType aType)
{
    NSString *name = [VJXPin nameforType:aType];
	if (name)
        return name;
    return @"None";
}

- (void)controlPin
{
	NSLog(@"%s", _cmd);

	for (NSString *anInputPinName in self.entity.inputPins) {
		VJXInputPin *anInputPin = [self.entity inputPinWithName:anInputPinName];
		NSLog(@"name: %@, type: %@", anInputPin.name, controlForVJXPinType(anInputPin.type));
	}

}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		return 2; // input and output
	}

	if ([item isEqualToString:@"Input"])
		return [[self.entity inputPins] count];
	if ([item isEqualToString:@"Output"])
		return [[self.entity outputPins] count];
	return 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
	if ([item isEqualToString:@"Input"] || [item isEqualToString:@"Output"])
		return YES;
	return NO;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if ([[tableColumn identifier] isEqualToString:@"pinName"])
		return NO;
	return YES;
}


- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
	if (!item) {
		switch (index) {
			case 0:
				return @"Input";
			case 1:
				return @"Output";
		}
	}
    if (![item respondsToSelector:@selector(isEqualToString:)])
        return nil;

	if ([item isEqualToString:@"Input"])
		return [[self.entity inputPins] objectAtIndex:index];

	if ([item isEqualToString:@"Output"])
		return [[self.entity outputPins] objectAtIndex:index];
	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
	if (![item respondsToSelector:@selector(isEqualToString:)])
        return @"";

	if (([item isEqualToString:@"Input"] || [item isEqualToString:@"Output"]) && [[tableColumn identifier] isEqualToString:@"pinName"])
		return item;

	if ([item isEqualToString:@"Input"] || [item isEqualToString:@"Output"])
		return @"";


	if ([[tableColumn identifier] isEqualToString:@"pinName"])
		return item;

	VJXPin *aPin = nil;

	if ([[self.entity inputPins] indexOfObject:item] != NSNotFound)
		aPin = [self.entity inputPinWithName:item];
	else if ([[self.entity outputPins] indexOfObject:item] != NSNotFound)
		aPin = [self.entity outputPinWithName:item];

	return aPin ? [aPin readData] : @"TEST";
}

- (void)setStringSelectionPin:(NSOutlineView *)outlineView
{
    NSPopUpButtonCell *item = [outlineView selectedCell];
    NSInteger row = [outlineView selectedRow];
    NSString *pinName = [outlineView itemAtRow:row];
    VJXInputPin *aPin = [self.entity inputPinWithName:pinName];
    if (aPin) {
        VJXOutputPin *vPin = [VJXPin pinWithName:@"setter" andType:kVJXStringPin forDirection:kVJXOutputPin ownedBy:nil withSignal:nil];
        [vPin connectToPin:aPin];
        [vPin deliverData:[item titleOfSelectedItem]];
    }
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if (tableColumn == nil)
		return nil;

	if ([[tableColumn identifier] isEqualToString:@"pinName"])
		return nil;

	VJXPin *aPin = nil;

	if ([[self.entity inputPins] indexOfObject:item] != NSNotFound)
		aPin = [self.entity inputPinWithName:item];
	else if ([[self.entity outputPins] indexOfObject:item] != NSNotFound)
		aPin = [self.entity outputPinWithName:item];

	if (aPin == nil)
		return nil;

	NSCell *cell = nil;

	if (aPin.type == kVJXStringPin) {
		if (aPin.direction == kVJXInputPin && [aPin allowedValues] != nil) {
			cell = [[NSPopUpButtonCell alloc] init];
            [(NSPopUpButtonCell *)cell setTarget:self];
            [(NSPopUpButtonCell *)cell setAction:@selector(setStringSelectionPin:)];
            [(NSPopUpButtonCell *)cell addItemsWithTitles:[aPin allowedValues]];
            //[(NSPopUpButtonCell *)cell selectItemWithTitle:[aPin readData]];
		}
		else
			cell = [[NSTextFieldCell alloc] init];
	}
	else if (aPin.type == kVJXNumberPin) {
		cell = [[NSTextFieldCell alloc] init];
	}
	else {
		cell = [[NSButtonCell alloc] init];
	}

	return [cell autorelease];

}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
{
    // TODO - check if we are populating the input-pins part of the outlineview
    if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
        // ensure resetting selected values (since the button is re-constructed
        // each time that 'outlineView:dataCellForTableColumn:item:' is called
        NSInteger row = [outlineView selectedRow];
        NSString *pinName = [outlineView itemAtRow:row];
        VJXInputPin *aPin = [self.entity inputPinWithName:pinName];
        //[(NSPopUpButtonCell *)cell addItemsWithTitles:[aPin allowedValues]];
        [(NSPopUpButtonCell *)cell selectItemWithTitle:[aPin readData]];
    }
}

@end
