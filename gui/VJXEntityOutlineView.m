//
//  VJXEntityOutlineView.m
//  VeeJay
//
//  Created by Igor Sutton on 10/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntityOutlineView.h"
#import "VJXInputPin.h"


@implementation VJXEntityOutlineView

@synthesize entity;

- (id)initWithFrame:(NSRect)frameRect
{
    if ((self = [super initWithFrame:frameRect]) != nil) {
        virtualOutputPins = [[NSMutableDictionary alloc] init];
        virtualOutputPinNames = [[NSMutableArray alloc] init];
        dataCells = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)awakeFromNib
{
    virtualOutputPins = [[NSMutableDictionary alloc] init];
    virtualOutputPinNames = [[NSMutableArray alloc] init];
    dataCells = [[NSMutableDictionary alloc] init];
    [self setDelegate:self];
    [self setDataSource:self];
}

- (void)dealloc
{
    [virtualOutputPins release];
    [super dealloc];
}

- (void)setEntity:(VJXEntity *)anEntity
{
    if (entity == anEntity)
        return;

    entity = anEntity;

    [self setUpPins];
}

- (void)setUpPins
{
    [virtualOutputPins removeAllObjects];
    [virtualOutputPinNames removeAllObjects];

    // Create an output pin for each input pin in the current entity.
    for (NSString *inputPinName in [entity inputPins]) {
        VJXInputPin *inputPin = [entity inputPinWithName:inputPinName];
        VJXOutputPin *outputPin = [VJXPin pinWithName:inputPin.name andType:inputPin.type forDirection:kVJXOutputPin ownedBy:nil withSignal:nil];
        [outputPin connectToPin:inputPin];
        [virtualOutputPins setObject:outputPin forKey:outputPin.name];
        [virtualOutputPinNames addObject:outputPin.name];
    }
}

- (IBAction)commitChange:(id)sender
{
    NSLog(@"%s -> %i", _cmd, [sender tag]);
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
	if (!item) {
		return 1; // input and output
	}

	if ([item isEqualToString:@"Input"])
		return [virtualOutputPinNames count];

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

	if ([item isEqualToString:@"Input"]) {
        return [virtualOutputPinNames objectAtIndex:index];
    }

	return nil;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([[tableColumn identifier] isEqualToString:@"pinName"]) {
        return item;
    }
    else {
        if ([item isEqualToString:@"Input"] || [item isEqualToString:@"Output"])
            return @"";

        VJXPin *aPin = nil;

        if ([virtualOutputPins objectForKey:item] != nil) {
            NSString *pinName = ((VJXOutputPin *)[virtualOutputPins objectForKey:item]).name;
            aPin = [self.entity inputPinWithName:pinName];
        }
        return [aPin readData];
    }
    return nil;
}

- (NSCell *)outlineView:(NSOutlineView *)outlineView dataCellForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
	if (tableColumn == nil)
		return nil;

	if ([[tableColumn identifier] isEqualToString:@"pinName"])
		return nil;

    NSActionCell *cell = [dataCells objectForKey:item];

    if (cell != nil) {
        NSLog(@"%@ -> %s",[cell target], [cell action]);
        return cell;
    }


    VJXOutputPin *aPin = [virtualOutputPins objectForKey:item];

	if (aPin == nil)
		return nil;

	if (aPin.type == kVJXStringPin) {
		if (aPin.direction == kVJXInputPin && [aPin allowedValues] != nil) {
			cell = [[NSPopUpButtonCell alloc] init];
            [cell setTarget:self];
            [cell setAction:@selector(commitChange:)];
            [(NSPopUpButtonCell *)cell addItemsWithTitles:[aPin allowedValues]];
		}
		else {
			cell = [[NSTextFieldCell alloc] init];
            [cell setTarget:self];
            [cell setAction:@selector(commitChange:)];
            [cell setEditable:YES];
        }
	}
	else if (aPin.type == kVJXNumberPin) {
		cell = [[NSTextFieldCell alloc] init];
        [cell setTarget:self];
        [cell setAction:@selector(commitChange:)];
        [cell setEditable:YES];
	}
	else {
		cell = [[NSButtonCell alloc] init];
	}

    [dataCells setObject:cell forKey:item];

	return [cell autorelease];

}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
{
    if ([[tableColumn identifier] isEqualToString:@"control"]) {
        // TODO - check if we are populating the input-pins part of the outlineview
        if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
            // ensure resetting selected values (since the button is re-constructed
            // each time that 'outlineView:dataCellForTableColumn:item:' is called
            NSInteger row = [outlineView selectedRow];
            NSString *pinName = [outlineView itemAtRow:row];
            VJXInputPin *aPin = [self.entity inputPinWithName:pinName];
            [(NSPopUpButtonCell *)cell selectItemWithTitle:[aPin readData]];
        }
    }
}

@end
