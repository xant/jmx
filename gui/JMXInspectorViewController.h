//
//  JMXInspectorViewController.h
//  JMX
//
//  Created by Igor Sutton on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface JMXInspectorViewController : NSViewController {
    NSObjectController *entityController;
    NSViewController *inspectorPropertiesViewController;
    NSViewController *inspectorInputViewController;
    NSViewController *inspectorOutputViewController;
}

@property (nonatomic, retain) IBOutlet NSObjectController *entityController;
@property (nonatomic, assign) IBOutlet NSViewController *inspectorPropertiesViewController;
@property (nonatomic, assign) IBOutlet NSViewController *inspectorInputViewController;
@property (nonatomic, assign) IBOutlet NSViewController *inspectorOutputViewController;

@end
