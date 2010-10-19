//
//  VJXEntityInspectorPanel.m
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntityInspectorPanel.h"
#import "VJXBoardEntity.h"

@interface VJXEntityInspectorPanel (Private)
- (void)setEntity:(VJXBoardEntity *)entity;
@end

@implementation VJXEntityInspectorPanel

@synthesize entityName;
@synthesize pinInspector;
@synthesize inputPins;
@synthesize outputPins;
@synthesize producers;
@synthesize entityView;
@synthesize pinsProperties;
//@synthesize panel;

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

- (void)unsetEntity:(VJXBoardEntity *)entity
{
    if (entityView == entity)
        self.entityView = nil;
}

- (void)setEntity:(VJXBoardEntity *)boardEntity
{
    /*
    if (![self isVisible])
        [self setIsVisible:YES];
     */
    entityView = boardEntity;
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSInteger count = 0;
    if (aTableView == inputPins) {
        count = [[entityView.entity inputPins] count];
    } else if (aTableView == outputPins) {
        count = [[entityView.entity outputPins] count];
    } else if (aTableView == producers) {
        NSInteger selectedRow = [inputPins selectedRow];
        if (selectedRow >= 0) {
            NSArray *pins = [entityView.entity inputPins];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            VJXInputPin *pin = [entityView.entity inputPinWithName:pinName];
            return [pin.producers count];
        }
    }
    return count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{ 
    NSArray *pins = nil;
    if (entityView.entity) {
        if (aTableView == inputPins) {
            @synchronized(entityView.entity) {
                pins = [entityView.entity inputPins];
            }
            if ([[aTableColumn identifier] isEqualTo:@"pinName"])
                return [pins objectAtIndex:rowIndex];
            else
                return [[entityView.entity inputPinWithName:[pins objectAtIndex:rowIndex]] typeName];
        } else if (aTableView == outputPins) {
            @synchronized(entityView.entity) {
                pins = [entityView.entity outputPins];
            }
            if ([[aTableColumn identifier] isEqualTo:@"pinName"])
                return [pins objectAtIndex:rowIndex];
            else
                return [[entityView.entity outputPinWithName:[pins objectAtIndex:rowIndex]] typeName];        
        } else if (aTableView == producers) {
            NSInteger selectedRow = [inputPins selectedRow];
            if (selectedRow >= 0) {
                @synchronized(entityView.entity) {
                    pins = [entityView.entity inputPins];
                }
                NSString *pinName = [pins objectAtIndex:selectedRow];
                VJXInputPin *pin = [entityView.entity inputPinWithName:pinName];
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
            NSArray *pins = [entityView.entity inputPins];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            VJXInputPin *pin = [entityView.entity inputPinWithName:pinName];
            if ([pin moveProducerFromIndex:(NSUInteger)srcRow toIndex:(NSUInteger)(srcRow < row)?row-1:row]) {
                [aTableView reloadData];
                return YES;
            }
        }
    }
    return NO;
}

- (void)anEntityWasSelected:(NSNotification *)aNotification
{
    VJXBoardEntity *entity = [aNotification object];
    [self setEntity:entity];
	[self.pinsProperties setDataSource:entity];
	[self.pinsProperties setDelegate:entity];
	[self.pinsProperties expandItem:nil expandChildren:YES];
}

- (void)anEntityWasRemoved:(NSNotification *)aNotification
{
    VJXEntity *entity = [aNotification object];
    if (entityView && entityView.entity == entity) {
        [self.pinsProperties setDataSource:nil];
        [self.pinsProperties setDelegate:nil];
        [self.pinsProperties reloadData];
        self.entityView = nil; // TODO - clear the listview
    }
}

@end
