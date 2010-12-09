//
//  JMXEntitiesController.m
//  JMX
//
//  Created by Igor Sutton on 11/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXEntitiesController.h"
#import "JMXEntityLayer.h"

@implementation JMXEntitiesController

- (void)awakeFromNib
{
    [self setPreservesSelection:NO];
}

- (void)addObject:(id)object
{
    [[self selectedObjects] makeObjectsPerformSelector:@selector(unselect)];
    [super addObject:object];
    ((JMXEntityLayer *)object).selected = YES;
}

- (BOOL)setSelectedObjects:(NSArray *)objects
{
    [[self selectedObjects] makeObjectsPerformSelector:@selector(unselect)];
    BOOL rv = [super setSelectedObjects:objects];
    for (JMXEntityLayer *entity in objects)
        entity.selected = YES;
    return rv;
}

- (void)unselectAll
{
    [self setSelectedObjects:[NSArray array]];
}

@end
