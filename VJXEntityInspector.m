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
    //[inputPins setDataSource:inspector];
    if ([inputPins dataSource] != self)
        [inputPins setDataSource:self];
    [inputPins reloadData];
    if ([outputPins dataSource] != self)
        [outputPins setDataSource:self];
    [outputPins reloadData];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    NSInteger count = 0;
    if (aTableView == inputPins) {
        count = [entity.entity.inputPins count];
    } else if (aTableView == outputPins) {
        count = [entity.entity.outputPins count];
    }
    return count;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{ 
    if (aTableView == inputPins) {
        NSArray *pins = [entity.entity.inputPins allKeys];
        if ([[aTableColumn identifier] isEqualTo:@"pinName"])
            return [pins objectAtIndex:rowIndex];
        else
            return [[entity.entity.inputPins objectForKey:[pins objectAtIndex:rowIndex]] typeName];
    } else if (aTableView == outputPins) {
        NSArray *pins = [entity.entity.outputPins allKeys];
        if ([[aTableColumn identifier] isEqualTo:@"pinName"])
            return [pins objectAtIndex:rowIndex];
        else
            return [[entity.entity.outputPins objectForKey:[pins objectAtIndex:rowIndex]] typeName];        
    }
    return nil;
}

@end
