//
//  VJXLayerArrayController.m
//  VeeJay
//
//  Created by Igor Sutton on 8/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXLayerArrayController.h"


@implementation VJXLayerArrayController

- (BOOL)tableView:(NSTableView *)tv writeRowsWithIndexes:(NSIndexSet *)rowIndexes
     toPasteboard:(NSPasteboard*)pboard
{
    NSLog(@"%s", _cmd);

    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];
    [pboard declareTypes:[NSArray arrayWithObject:@"LayerTableViewDataType"] owner:self];
    [pboard setData:data forType:@"LayerTableViewDataType"];

    return YES;
}

- (NSDragOperation)tableView:(NSTableView*)tv
                validateDrop:(id <NSDraggingInfo>)info
                 proposedRow:(NSInteger)row
       proposedDropOperation:(NSTableViewDropOperation)op
{
    return NSDragOperationEvery;
}

- (BOOL)tableView:(NSTableView *)aTableView
       acceptDrop:(id <NSDraggingInfo>)info
              row:(NSInteger)row
    dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSData* rowData = [pboard dataForType:@"LayerTableViewDataType"];
    NSIndexSet* rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];
    NSInteger dragRow = [rowIndexes firstIndex];
    NSMutableArray *layers = self.content;
    [layers exchangeObjectAtIndex:dragRow withObjectAtIndex:row];
    return YES;
}

@end
