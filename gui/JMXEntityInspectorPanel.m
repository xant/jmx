//
//  JMXEntityInspectorPanel.m
//  JMX
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXEntityInspectorPanel.h"
#import "JMXEntityLayer.h"

@interface JMXEntityInspectorPanel (Private)
- (void)setEntity:(JMXEntityLayer *)entity;
@end

@implementation JMXEntityInspectorPanel

- (id)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self) {
        entityName = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasSelected:) name:@"JMXBoardEntityWasSelected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasRemoved:) name:@"JMXBoardEntityWasRemoved" object:nil];
        dataCells =[[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [dataCells release];
    [super dealloc];
}

- (void)clearTableView:(NSTableView *)tableView
{
    [tableView setDataSource:nil];
    [tableView setDelegate:nil];
    [tableView reloadData];
}

- (void)unsetEntity:(JMXEntityLayer *)anEntityLayer
{
    if (entityLayer == anEntityLayer)
        entityLayer = nil;
}

- (void)setEntity:(JMXEntityLayer *)anEntityLayer
{
    entityLayer = anEntityLayer;

    //[inputPins setDataSource:inspector];
    if ([inputPins dataSource] != self) {
        [inputPins setDataSource:self];
        [inputPins setDelegate:self];
    }
    [inputPins reloadData];
    if ([outputPins dataSource] != self) {
        [outputPins setDataSource:self];
        [outputPins setDelegate:self];
    }
    [outputPins reloadData];

    if ([producers dataSource] != self) {
        [producers setDataSource:self];
        [producers setDelegate:self];
        [producers registerForDraggedTypes:[NSArray arrayWithObject:@"PinRowIndex"]];
    }
    [dataCells removeAllObjects];
    [producers reloadData];
}

#pragma mark -
#pragma mark NSTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSInteger count = 0;
    if (aTableView == inputPins) {
        count = [[entityLayer.entity inputPins] count];
    } else if (aTableView == outputPins) {
        count = [[entityLayer.entity outputPins] count];
    } else if (aTableView == producers) {
        NSInteger selectedRow = [inputPins selectedRow];
        if (selectedRow >= 0) {
            NSArray *pins = [entityLayer.entity inputPins];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            JMXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
            return [pin.producers count];
        }
    }
    return count;
}

- (void)tableView:(NSTableView *)aTableView
   setObjectValue:(id)anObject
   forTableColumn:(NSTableColumn *)aTableColumn
              row:(NSInteger)rowIndex
{
    if (aTableView == inputPins && [[aTableColumn identifier] isEqualTo:@"pinValue"]) {
        NSArray *pins;
        @synchronized(entityLayer.entity) {
            pins = [entityLayer.entity inputPins];
        }
        JMXInputPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:rowIndex]];
        if (pin) {
            if (pin.type == kJMXNumberPin) {
                if ([anObject isKindOfClass:[NSString class]])
                    [pin deliverData:[NSNumber numberWithInt:[anObject intValue]]];
                else if ([anObject isKindOfClass:[NSNumber class]])
                    [pin deliverData:anObject];
            } else if (pin.type == kJMXStringPin) {
                if ([anObject isKindOfClass:[NSString class]])
                    [pin deliverData:anObject];
                else if ([anObject isKindOfClass:[NSNumber class]])
                    [pin deliverData:[NSString stringWithFormat:@"%.2f", [anObject floatValue]]]; // XXX
            }
        }
    }
}

- (void)setNumberValue:(id)sender
{
    if (sender == inputPins) {
        NSArray *pins;
        @synchronized(entityLayer.entity) {
            pins = [entityLayer.entity inputPins];
        }
        JMXInputPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:[sender selectedRow]]];
        if (pin) {
            NSCell *cell = [sender preparedCellAtColumn:1 row:[sender selectedRow]];
        }
    }
}

- (void)setPopupButtonValue:(id)sender
{
    if (sender == inputPins) {
        NSArray *pins;
        @synchronized(entityLayer.entity) {
            pins = [entityLayer.entity inputPins];
        }
        JMXInputPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:[sender selectedRow]]];
        if (pin) {
            NSCell *cell = [sender preparedCellAtColumn:1 row:[sender selectedRow]];
            [pin deliverData:[(NSPopUpButtonCell *)cell titleOfSelectedItem]];
            // XXX - the following line is necessary to have the table updated if the new selections 
            //       involves creation/removal of pins (so new pins must be enumerated in the table)
            //       for instance JMXCoreImageFilters, when selecting a new filter
            [inputPins performSelector:@selector(reloadData) withObject:nil afterDelay:0.1];
        }
    }
}

- (void)setSliderValue:(id)sender
{
    if (sender == inputPins) {
        NSArray *pins;
        @synchronized(entityLayer.entity) {
            pins = [entityLayer.entity inputPins];
        }
        JMXInputPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:[sender selectedRow]]];
        if (pin) {
            NSCell *cell = [sender preparedCellAtColumn:1 row:[sender selectedRow]];
            [pin deliverData:[NSNumber numberWithFloat:[cell floatValue]]];
        }
    }
}

- (NSCell *)tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSActionCell *cell = nil;
    
    if (entityLayer.entity && tableColumn != nil) {
        NSArray *pins = nil;
        if (tableView == inputPins) {
            if (![[tableColumn identifier] isEqualTo:@"pinName"]) {
                @synchronized(entityLayer.entity) {
                    pins = [entityLayer.entity inputPins];
                }
                JMXPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:row]];
                cell = [dataCells objectForKey:pin];
                if (cell != nil)
                    return cell;
                if (pin.type == kJMXStringPin || pin.type == kJMXTextPin) {
                    if ([pin allowedValues]) {
                        cell = [[NSPopUpButtonCell alloc] init];
                        [(NSPopUpButtonCell *)cell addItemsWithTitles:[pin allowedValues]];
                        [(NSPopUpButtonCell *)cell setPullsDown:NO];
                    } else {
                        cell = [[[NSTextFieldCell alloc] init] autorelease];
                        [cell setEditable:YES];
                    }
                    [cell setControlSize:NSSmallControlSize];
                    [cell setFont:[NSFont labelFontOfSize:[NSFont smallSystemFontSize]]];
                    [cell setTarget:self];
                    [cell setAction:@selector(setPopupButtonValue:)];
                } else if (pin.type == kJMXNumberPin) {
                    if (pin.minValue && pin.maxValue) {
                        cell = [[[NSSliderCell alloc] init] autorelease];
                        [(NSSliderCell *)cell setMinValue:[pin.minValue doubleValue]];
                        [(NSSliderCell *)cell setMaxValue:[pin.maxValue doubleValue]];
                        [cell setControlSize:NSSmallControlSize];
                        [cell setContinuous:YES];
                        [cell setTarget:self];
                        [cell setAction:@selector(setSliderValue:)];
                        [cell setTitle:[pin name]];
                    } else {
                        cell = [[[NSTextFieldCell alloc] init] autorelease];
                        NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
                        [nf setMaximumFractionDigits:2];
                        [nf setMinimumFractionDigits:2];
                        [nf setMinimumIntegerDigits:1];
                        [cell setFormatter:nf];     
                        [nf release];
                        [cell setEditable:YES];
                        [cell setTarget:self];
                        [cell setAction:@selector(setNumberValue:)];
                    }
                } else {
                    cell = [[[NSTextFieldCell alloc] init] autorelease];
                }
                [dataCells setObject:cell forKey:pin];
            }
        }
    }
    return cell;
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *pins = nil;
    if (entityLayer.entity && aTableView == inputPins) {
        @synchronized(entityLayer.entity) {
            pins = [entityLayer.entity inputPins];
        }
        if ([[aTableColumn identifier] isEqualTo:@"pinValue"]) {
            @synchronized(entityLayer.entity) {
                pins = [entityLayer.entity inputPins];
            }
            JMXPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:rowIndex]];
            if ([aCell isKindOfClass:[NSPopUpButtonCell class]])
                 [(NSPopUpButtonCell *)aCell selectItemWithTitle:[pin readData]];
            else if ([aCell isKindOfClass:[NSTextFieldCell class]]) {
                id value = [pin readData];
                if ([value isKindOfClass:[NSNumber class]]) {
                    [(NSTextFieldCell *)aCell setStringValue:[NSString stringWithFormat:@"%.2f", [value floatValue]]];
                }
            }
        }
    }
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *pins = nil;
    if (entityLayer.entity) {
        if (aTableView == inputPins) {
            @synchronized(entityLayer.entity) {
                pins = [entityLayer.entity inputPins];
            }
            if ([[aTableColumn identifier] isEqualTo:@"pinName"]) {
                return [pins objectAtIndex:rowIndex];
            } else {
                @synchronized(entityLayer.entity) {
                    pins = [entityLayer.entity inputPins];
                }
                JMXPin *pin = [entityLayer.entity inputPinWithName:[pins objectAtIndex:rowIndex]];
                return [pin readData];
            }
        } else if (aTableView == outputPins) {
            @synchronized(entityLayer.entity) {
                pins = [entityLayer.entity outputPins];
            }
            if ([[aTableColumn identifier] isEqualTo:@"pinName"])
                return [pins objectAtIndex:rowIndex];
            else
                return [[entityLayer.entity outputPinWithName:[pins objectAtIndex:rowIndex]] typeName];
        } else if (aTableView == producers) {
            NSInteger selectedRow = [inputPins selectedRow];
            if (selectedRow >= 0) {
                @synchronized(entityLayer.entity) {
                    pins = [entityLayer.entity inputPins];
                }
                NSString *pinName = [pins objectAtIndex:selectedRow];
                JMXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
                return [NSString stringWithFormat:@"%@",[[pin.producers objectAtIndex:rowIndex] description]];
            }
        }
    }
    return nil;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *aTableView =[notification object];
    // at the moment we are interested only in selection among inputPins
    if (aTableView == inputPins)
        [producers reloadData];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    if (aTableView == inputPins && [[aTableColumn identifier] isEqualTo:@"pinValue"])
        return YES;
    else
        return NO; // we don't allow editing items for now
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
    if (aTableView != producers)
        return nil;
    return [NSArray arrayWithObjects:@"PinRowIndex", nil];
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    if (aTableView != producers)
        return NO;

    NSUInteger row = [rowIndexes firstIndex];
    [pboard addTypes:[NSArray arrayWithObjects:@"PinRowIndex", nil] owner:(id)self];
    [pboard setData:[NSData dataWithBytes:&row length:sizeof(NSUInteger)] forType:@"PinRowIndex"];
    return YES;
}


- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)operation
{
    NSDragOperation dragOp = NSDragOperationMove;
    [aTableView setDropRow: row
             dropOperation: NSTableViewDropAbove];
    return dragOp;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if (aTableView != producers)
        return NO;
    NSInteger srcRow = -1;
    [[[info draggingPasteboard] dataForType:@"PinRowIndex"] getBytes:&srcRow length:sizeof(NSUInteger)];
    if (srcRow >= 0) {
        NSInteger selectedRow = [inputPins selectedRow];
        if (selectedRow >= 0) {
            NSArray *pins = [entityLayer.entity inputPins];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            JMXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
            if ([pin moveProducerFromIndex:(NSUInteger)srcRow toIndex:(NSUInteger)(srcRow < row)?row-1:row]) {
                [aTableView reloadData];
                return YES;
            }
        }
    }
    return NO;
}

#pragma mark -
#pragma mark Notifications

- (void)anEntityWasSelected:(NSNotification *)aNotification
{
    JMXEntityLayer *anEntityLayer = [aNotification object];
    [self setEntity:anEntityLayer];
}

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    JMXEntity *entity = [aNotification object];
    if (entityLayer && entityLayer.entity == entity) {
        entityLayer = nil;
        [self clearTableView:inputPins];
        [self clearTableView:outputPins];
        [self clearTableView:producers];
        [dataCells removeAllObjects];
    }
}

@end
