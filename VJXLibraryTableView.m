//
//  VJXLibraryTableView.m
//  VeeJay
//
//  Created by Igor Sutton on 10/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXLibraryTableView.h"

@implementation VJXLibraryTableView

- (void)awakeFromNib
{
	[self registerForDraggedTypes:[NSArray arrayWithObject:VJXLibraryTableViewDataType]];
}

- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
	return NSDragOperationEvery;
}

- (NSImage *)dragImageForRowsWithIndexes:(NSIndexSet *)dragRows tableColumns:(NSArray *)tableColumns event:(NSEvent *)dragEvent offset:(NSPointPointer)dragImageOffset
{
    id<NSTableViewDataSource> dataSource = [self dataSource];

    NSMutableAttributedString *className = [[NSMutableAttributedString alloc] initWithString:[dataSource tableView:nil objectValueForTableColumn:nil row:[dragRows firstIndex]]
                                                                                  attributes:[NSDictionary dictionaryWithObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName]];
    NSSize size = [className size];
    NSRect aRect = NSMakeRect(0.0, 0.0, size.width + 20.0, size.height + 20.0);

    NSImage *anImage = [[NSImage alloc] initWithSize:aRect.size];

    [anImage lockFocus];
    NSBezierPath *thePath = [[NSBezierPath alloc] init];
    [[NSColor colorWithDeviceWhite:0.0 alpha:0.5] set];
    [thePath appendBezierPathWithRoundedRect:aRect xRadius:5.0 yRadius:5.0];
    [thePath fill];
    [thePath release];
    [className drawInRect:NSMakeRect(10.0, 10.0, size.width, size.height)];
    [anImage unlockFocus];

    return [anImage autorelease];
}

@end
