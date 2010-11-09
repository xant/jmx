//
//  JMXLibraryTableViewDelegate.m
//  JMX
//
//  Created by Igor Sutton on 10/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXLibraryTableViewDelegate.h"
#import "JMXContext.h"

@implementation JMXLibraryTableViewDelegate

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	JMXContext *sharedContext = [JMXContext sharedContext];
	return [[sharedContext registeredClasses] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	JMXContext *sharedContext = [JMXContext sharedContext];
	NSString *className = [[[sharedContext registeredClasses] objectAtIndex:row] className];
	return className;
}

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
	JMXContext *sharedContext = [JMXContext sharedContext];
	NSString *className = [[[sharedContext registeredClasses] objectAtIndex:[rowIndexes firstIndex]] className];
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:className];
	[pboard declareTypes:[NSArray arrayWithObject:@"JMXLibraryTableViewDataType"] owner:self];
	[pboard setData:data forType:@"JMXLibraryTableViewDataType"];
	return YES;
}

@end
