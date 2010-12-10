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
    [(JMXEntityLayer *)object select];
}

- (BOOL)setSelectedObjects:(NSArray *)objects
{
    [[self selectedObjects] makeObjectsPerformSelector:@selector(unselect)];
    BOOL rv = [super setSelectedObjects:objects];
    if (rv)
        [objects makeObjectsPerformSelector:@selector(select)];
    return rv;
}

- (void)unselectAll
{
    [self setSelectedObjects:[NSArray array]];
}

@end
