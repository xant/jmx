//
//  JMXInspectorViewController.m
//  JMX
//
//  Created by Igor Sutton on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXInspectorViewController.h"


@implementation JMXInspectorViewController

@synthesize entityController;
@synthesize inspectorPropertiesViewController;
@synthesize inspectorInputViewController;
@synthesize inspectorOutputViewController;

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
