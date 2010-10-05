//
//  VJXLibraryTableViewDelegate.m
//  VeeJay
//
//  Created by Igor Sutton on 10/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXLibraryTableViewDelegate.h"
#import "VJXContext.h"

@implementation VJXLibraryTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	VJXContext *sharedContext = [VJXContext sharedContext];
	return [[sharedContext registeredClasses] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	VJXContext *sharedContext = [VJXContext sharedContext];
	NSString *className = [[[sharedContext registeredClasses] objectAtIndex:row] className];
	return className;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	VJXContext *sharedContext = [VJXContext sharedContext];
	NSString *className = [[[sharedContext registeredClasses] objectAtIndex:[rowIndexes firstIndex]] className];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:className];
	[pboard declareTypes:[NSArray arrayWithObject:VJXLibraryTableViewDataType] owner:self];
	[pboard setData:data forType:VJXLibraryTableViewDataType];
	return YES;
}

@end
