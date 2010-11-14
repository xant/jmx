//
//  JMXDocumentSplitViewDelegate.m
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXDocumentSplitViewDelegate.h"


@implementation JMXDocumentSplitViewDelegate

@synthesize inspectorView;
@synthesize libraryView;

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	if (subview == inspectorView || subview == libraryView) {
		return YES;
	}
	return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldCollapseSubview:(NSView *)subview forDoubleClickOnDividerAtIndex:(NSInteger)dividerIndex
{
	if ((dividerIndex == 0 && subview == libraryView) || (dividerIndex == 1 && subview == inspectorView))
		return YES;
	return NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex
{
	if (dividerIndex == 0)
		return 200.0f;
	if (dividerIndex == 1)
		return [splitView bounds].size.width - 300.0f;	
	return proposedMax;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
	if (dividerIndex == 0)
		return 200.0f;
	if (dividerIndex == 1) {
		return [splitView bounds].size.width - 300.0f;
	}
	return proposedMinimumPosition;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	if (dividerIndex == 1)
		return YES;
	return NO;
}

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview
{
	if (subview == inspectorView || subview == libraryView) {
		return NO;
	}
	return YES;
}

@end
