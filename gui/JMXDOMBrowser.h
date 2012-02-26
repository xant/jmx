//
//  JMXDOMBrowser.h
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JMXDOMBrowser : NSPanel <NSOutlineViewDelegate, NSOutlineViewDataSource>
{
    IBOutlet NSOutlineView *outlineView;
}
@end
