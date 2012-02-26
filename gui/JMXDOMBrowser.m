//
//  JMXDOMBrowser.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXDOMBrowser.h"
#import "JMXContext.h"
#import "JMXGraph.h"
#import "JMXElement.h"
#import "JMXAttribute.h"

@implementation JMXDOMBrowser

- (void)updateBrowser:(NSNotification *)notification
{
    [outlineView reloadData];
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [outlineView reloadData];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXEntityWasCreated"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXEntityWasDestroyed"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXEntityWasModified"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXPinConnected"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXPinDisconnected"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXEntityPinAdded"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateBrowser:)
                                                 name:@"JMXEntityPinRemoved"
                                               object:nil];
    
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (!item)
        return [[JMXContext sharedContext].dom rootElement];
    return [(NSXMLNode *)item childAtIndex:index];
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (!item)
        return 1;
    return [(NSXMLNode *)item childCount];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([tableColumn.identifier isEqualToString:@"name"]) {
        if ([item kind] == NSXMLCommentKind) {
            return [item description];
        } else {
            return [(NSXMLNode *)item name];
        }
    } else {
        if ([item isKindOfClass:[JMXElement class]]) {
            NSMutableString *attrString = [NSMutableString stringWithCapacity:255];
            for (JMXAttribute *attr in [item attributes]) {
                [attrString appendFormat:@"%@=%@ ", [attr name], [attr stringValue]];
            }
            return attrString;
        } else {
            return [(NSXMLNode *)item stringValue];
        }
    }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    return [(NSXMLNode *)item childCount] ? YES : NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [outlineView release];
    [super dealloc];
}
@end
