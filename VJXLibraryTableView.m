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

@end
