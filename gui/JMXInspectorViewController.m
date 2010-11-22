//
//  JMXInspectorViewController.m
//  JMX
//
//  Created by Igor Sutton on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXInspectorViewController.h"
#import "JMXEntityLayer.h"
#import "JMXEntityProducerTableViewDelegate.h"

@implementation JMXInspectorViewController

@synthesize entityController;
@synthesize entityOutlineView;
@synthesize entityProducerTableView;
@synthesize entityOutlineViewDelegate;
@synthesize entityProducerTableViewDelegate;

#pragma mark -
#pragma mark Initialization

- (void)awakeFromNib
{
    [entityProducerTableView registerForDraggedTypes:[NSArray arrayWithObject:@"PinRowIndex"]];
    [entityController addObserver:self forKeyPath:@"content" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
}

- (void)dealloc
{
    [entityProducerTableView unregisterDraggedTypes];
    [entityController removeObserver:self forKeyPath:@"content"];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqual:@"content"]) {
        id anEntity = nil;
        NSArray *selectedObjects = [[(NSObjectController *)object selectedObjects] objectAtIndex:0];
        if ([selectedObjects count] > 0) {
            anEntity = [(JMXEntityLayer *)[selectedObjects objectAtIndex:0] entity];
        }
        entityOutlineViewDelegate.entity = anEntity;
        [entityOutlineView performSelector:@selector(reloadData) withObject:nil afterDelay:0];

        entityProducerTableViewDelegate.entity = anEntity;
        entityProducerTableViewDelegate.pinName = nil;
        [entityProducerTableView performSelector:@selector(reloadData) withObject:nil afterDelay:0];
    }
}

#pragma mark -
#pragma mark NSViewController

- (void)setView:(NSView *)aView
{
    [super setView:aView];
    if (aView) {
        [aView setNextResponder:self];
    }
}

@end
