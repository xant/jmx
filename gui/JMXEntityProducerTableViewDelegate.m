//
//  JMXEntityProducerTableViewDelegate.m
//  JMX
//
//  Created by Igor Sutton on 11/22/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXEntityProducerTableViewDelegate.h"
#import "JMXEntity.h"


@implementation JMXEntityProducerTableViewDelegate

@synthesize entity;
@synthesize pinName;


- (void)awakeFromNib
{
    pin = nil;
    
    [self addObserver:self forKeyPath:@"pinName" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"pinName"] && entity != nil) {
        pin = [entity inputPinWithName:pinName];
    }
}

#pragma mark -
#pragma mark NSTableViewDelegate


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    if (pin == nil)
        return 0;
    
    return [pin.producers count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return [[pin producers] objectAtIndex:rowIndex];
}

- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return false; // we don't allow editing items for now
}

- (NSArray *)tableView:(NSTableView *)aTableView namesOfPromisedFilesDroppedAtDestination:(NSURL *)dropDestination forDraggedRowsWithIndexes:(NSIndexSet *)indexSet
{
    return [NSArray arrayWithObjects:@"PinRowIndex", nil];
}

- (BOOL)tableView:(NSTableView *)aTableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    NSUInteger row = [rowIndexes firstIndex];
    [pboard addTypes:[NSArray arrayWithObjects:@"PinRowIndex", nil] owner:(id)self];
    [pboard setData:[NSData dataWithBytes:&row length:sizeof(NSUInteger)] forType:@"PinRowIndex"];
    return YES;
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id <NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    NSDragOperation dragOp = NSDragOperationMove;
    [aTableView setDropRow:row dropOperation:NSTableViewDropAbove];
    return dragOp;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSInteger srcRow = -1;
    [[[info draggingPasteboard] dataForType:@"PinRowIndex"] getBytes:&srcRow length:sizeof(NSUInteger)];
    
    if (srcRow >= 0 && [pin moveProducerFromIndex:(NSUInteger)srcRow toIndex:(NSUInteger)((srcRow < row) ? row - 1 : row)]) {
        [aTableView reloadData];
        return YES;
    }
    return NO;
}

@end
