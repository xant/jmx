//
//  JMXEntityOutlineView.m
//  JMX
//
//  Created by Igor Sutton on 10/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXEntityOutlineView.h"
#import "JMXInputPin.h"


@implementation JMXEntityOutlineView

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
    [virtualOutputPinNames release];
    [dataCells release];
    [super dealloc];
}

- (void)setEntity:(JMXEntity *)anEntity
{
    if (entity == anEntity)
        return;

    entity = anEntity;

    [self setUpPins];
}

- (void)setUpPins
{
    [[virtualOutputPins allValues] makeObjectsPerformSelector:@selector(disconnectAllPins)];
    [virtualOutputPins removeAllObjects];
    [virtualOutputPinNames removeAllObjects];

    // Create an output pin for each input pin in the current entity.
    for (NSString *inputPinName in [entity inputPins]) {
        JMXInputPin *inputPin = [entity inputPinWithName:inputPinName];

        // Skip this pin if it's already connected.
        if (!inputPin.multiple && inputPin.connected)
            continue;

        JMXOutputPin *outputPin = [JMXPin pinWithName:inputPin.name andType:inputPin.type forDirection:kJMXOutputPin ownedBy:nil withSignal:nil];
        [outputPin connectToPin:inputPin];
        [virtualOutputPins setObject:outputPin forKey:outputPin.name];
        [virtualOutputPinNames addObject:outputPin.name];
    }
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

        JMXPin *aPin = [[[[virtualOutputPins objectForKey:item] receivers] allKeys] lastObject];
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
        return cell;
    }

    JMXOutputPin *aPin = [virtualOutputPins objectForKey:item];

	if (aPin == nil)
		return nil;

	if (aPin.type == kJMXStringPin) {

        // I expect the following code not to be a problem since each pin in
        // the inspector will be connected to just one receiver.
        JMXInputPin *anInputPin = [[[aPin receivers] allKeys] lastObject];

		if (anInputPin && [anInputPin allowedValues] != nil) {
            cell = [[[NSPopUpButtonCell alloc] init] autorelease];
            [(NSPopUpButtonCell *)cell addItemsWithTitles:[anInputPin allowedValues]];

            NSString *aValue = [anInputPin readData];
            [(NSPopUpButtonCell *)cell selectItemWithTitle:aValue];
            [(NSPopUpButtonCell *)cell setPullsDown:NO];
		}
		else {
            cell = [[[NSTextFieldCell alloc] init] autorelease];
        }
	}
	else if (aPin.type == kJMXNumberPin) {
        JMXInputPin *anInputPin = [[[aPin receivers] allKeys] lastObject];
        if (anInputPin.minValue && anInputPin.maxValue) {
            NSSliderCell *sliderCell = [[[NSSliderCell alloc] init] autorelease];
            [sliderCell setMinValue:[anInputPin.minValue doubleValue]];
            [sliderCell setMaxValue:[anInputPin.maxValue doubleValue]];
            [sliderCell setControlSize:NSSmallControlSize];
            cell = sliderCell;
        }
        else {
            cell = [[[NSTextFieldCell alloc] init] autorelease];
            NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
            [nf setMaximumFractionDigits:2];
            [nf setMinimumFractionDigits:2];
            [nf setMinimumIntegerDigits:1];
            [cell setFormatter:nf];
            [nf release];
            [cell setEditable:YES];
        }
	}
	else {
        cell = [[[NSButtonCell alloc] init] autorelease];
	}

    [dataCells setObject:cell forKey:item];

	return cell;

}

- (void)outlineView:(NSOutlineView *)outlineView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)item;
{
    if ([[tableColumn identifier] isEqualToString:@"control"]) {
        NSActionCell *cell = [dataCells objectForKey:item];
        if ([cell isKindOfClass:[NSPopUpButtonCell class]]) {
            NSString *aValue = [[[[[virtualOutputPins objectForKey:item] receivers] allKeys] lastObject] readData];
            [(NSPopUpButtonCell *)cell selectItemWithTitle:aValue];
        }
    }
}

- (void)outlineView:(NSOutlineView *)outlineView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    JMXOutputPin *outputPin = [virtualOutputPins objectForKey:item];
    if (outputPin.type == kJMXNumberPin) {
        NSNumber *aNumber = [NSNumber numberWithFloat:[object floatValue]];
        [outputPin deliverData:aNumber];
    }
    else if (outputPin.type == kJMXStringPin) {
        NSActionCell *cell = [dataCells objectForKey:item];
        // If it was a multiple choice menu, we might receive a NSNumber here
        // indicating the tag of the index of the item the user chose.
        if ([cell isKindOfClass:[NSPopUpButtonCell class]] && [object isKindOfClass:[NSNumber class]]) {
            [outputPin deliverData:[[(NSPopUpButtonCell *)cell itemAtIndex:[object intValue]] title]];
        }
        else {
            NSAssert([object isKindOfClass:[NSString class]], @"Object must be a NSString");
            [outputPin deliverData:object];
        }
    }
    [self reloadItem:item];
}
@end
