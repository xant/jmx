//
//  VJXEntityInspector.m
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXEntityInspector.h"
#import "VJXBoardDelegate.h"

@interface VJXEntityInspector (Private)
- (void)setEntity:(VJXBoardEntity *)entity;
@end

@implementation VJXEntityInspector

static VJXEntityInspector *inspector = nil;

@synthesize entity, panel;

+ (void)setPanel:(VJXEntityInspectorPanel *)aPanel
{
    if (!inspector)
        inspector = [[VJXEntityInspector alloc] init];
    inspector.panel = aPanel;

}

+ (void)unsetEntity:(VJXBoardEntity *)entity
{
    if (inspector.entity == entity)
        inspector.entity = nil;
}

+ (void)setEntity:(VJXBoardEntity *)entity
{
    if (!inspector)
        inspector = [[VJXEntityInspector alloc] init];
    if (![inspector.panel isVisible])
        [inspector.panel setIsVisible:YES];
    // we will maintain a weak reference, the entity itself 
    // should take care of unsetting the inspectorpanel before being destroyed
    [inspector setEntity:entity];
}

- (void)setEntity:(VJXBoardEntity *)boardEntity
{
    entity = boardEntity;
    inputPins = panel.inputPins;
    outputPins = panel.outputPins;
    producers = panel.producers;
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
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSInteger count = 0;
    if (aTableView == inputPins) {
        count = [entity.entity.inputPins count];
    } else if (aTableView == outputPins) {
        count = [entity.entity.outputPins count];
    } else if (aTableView == producers) {
        NSInteger selectedRow = [inputPins selectedRow];
        if (selectedRow >= 0) {
            NSArray *pins = [[entity.entity.inputPins allKeys]
                             sortedArrayUsingComparator:^(id obj1, id obj2)
                             {
                                 return [obj1 compare:obj2];
                             }];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            VJXPin *pin = [entity.entity inputPinWithName:pinName];
            return [pin.producers count];
        }
    }
    return count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{ 
    if (aTableView == inputPins) {
        NSArray *pins = [[entity.entity.inputPins allKeys]
                            sortedArrayUsingComparator:^(id obj1, id obj2)
                                                        {
                                                            return [obj1 compare:obj2];
                                                        }];
        
        if ([[aTableColumn identifier] isEqualTo:@"pinName"])
            return [pins objectAtIndex:rowIndex];
        else
            return [[entity.entity.inputPins objectForKey:[pins objectAtIndex:rowIndex]] typeName];
    } else if (aTableView == outputPins) {
        NSArray *pins = [[entity.entity.outputPins allKeys]
                         sortedArrayUsingComparator:^(id obj1, id obj2)
                         {
                             return [obj1 compare:obj2];
                         }];
        if ([[aTableColumn identifier] isEqualTo:@"pinName"])
            return [pins objectAtIndex:rowIndex];
        else
            return [[entity.entity.outputPins objectForKey:[pins objectAtIndex:rowIndex]] typeName];        
    } else if (aTableView == producers) {
        NSInteger selectedRow = [inputPins selectedRow];
        if (selectedRow >= 0) {
            NSArray *pins = [[entity.entity.inputPins allKeys]
                             sortedArrayUsingComparator:^(id obj1, id obj2)
                             {
                                 return [obj1 compare:obj2];
                             }];
            NSString *pinName = [pins objectAtIndex:selectedRow];
            VJXPin *pin = [entity.entity inputPinWithName:pinName];
            return [NSString stringWithFormat:@"%@",[pin.producers objectAtIndex:rowIndex]];
        }
    }
    return nil;
}
                                 
- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSTableView *aTableView =[notification object];
    if (aTableView == inputPins)
        [producers reloadData];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    return false; // we don't allow editing items for now
}

@end
