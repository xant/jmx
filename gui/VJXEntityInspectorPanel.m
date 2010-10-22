//
//  VJXEntityInspectorPanel.m
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntityInspectorPanel.h"
#import "VJXEntityLayer.h"

@interface VJXEntityInspectorPanel (Private)
- (void)setEntity:(VJXEntityLayer *)entity;
@end

@implementation VJXEntityInspectorPanel

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        entityName = nil;
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasSelected:) name:@"VJXBoardEntityWasSelected" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(anEntityWasRemoved:) name:@"VJXBoardEntityWasRemoved" object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

- (void)clearTableView:(NSTableView *)tableView
{
    [tableView setDataSource:nil];
    [tableView setDelegate:nil];
    [tableView reloadData];

}

- (void)unsetEntity:(VJXEntityLayer *)anEntityLayer
{
    if (entityLayer == anEntityLayer)
        entityLayer = nil;
}

- (void)setEntity:(VJXEntityLayer *)anEntityLayer
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
            VJXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
            return [pin.producers count];
        }
    }
    return count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    NSArray *pins = nil;
    if (entityLayer.entity) {
        if (aTableView == inputPins) {
            @synchronized(entityLayer.entity) {
                pins = [entityLayer.entity inputPins];
            }
            if ([[aTableColumn identifier] isEqualTo:@"pinName"])
                return [pins objectAtIndex:rowIndex];
            else
                return [[entityLayer.entity inputPinWithName:[pins objectAtIndex:rowIndex]] typeName];
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
                VJXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
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
    return false; // we don't allow editing items for now
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
            VJXInputPin *pin = [entityLayer.entity inputPinWithName:pinName];
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
    VJXEntityLayer *anEntityLayer = [aNotification object];
    [self setEntity:anEntityLayer];
	[pinsProperties setDataSource:anEntityLayer];
	[pinsProperties setDelegate:anEntityLayer];
	[pinsProperties expandItem:nil expandChildren:YES];
    [pinsProperties reloadData];
}

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    VJXEntity *entity = [aNotification object];
    if (entityLayer && entityLayer.entity == entity) {
        entityLayer = nil;
        [self clearTableView:pinsProperties];
        [self clearTableView:inputPins];
        [self clearTableView:outputPins];
        [self clearTableView:producers];
    }
}

@end
