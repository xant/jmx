//
//  JMXDocumentSplitViewDelegate.h
//  JMX
//
//  Created by Igor Sutton on 11/14/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JMXDocumentSplitViewDelegate : NSObject <NSSplitViewDelegate> {
	NSView *libraryView;
}

@property (nonatomic,assign) IBOutlet NSView *libraryView;


@end
