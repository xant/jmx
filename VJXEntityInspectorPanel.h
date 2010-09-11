//
//  VJXEntityInspectorPanel.h
//  VeeJay
//
//  Created by xant on 9/11/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXEntityInspectorPanel : NSPanel {
    IBOutlet NSTextField *entityName;
    IBOutlet NSTabView *pinInspector;
    IBOutlet NSTableView *inputPins;
    IBOutlet NSTableView *outputPins;
    IBOutlet NSTableView *producers;
}

@property (readonly)NSTextField *entityName;
@property (readonly)NSTabView *pinInspector;
@property (readonly)NSTableView *inputPins;
@property (readonly)NSTableView *outputPins;
@property (readonly)NSTableView *producers;

@end
