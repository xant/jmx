//
//  JMXCodePanel.h
//  JMX
//
//  Created by Andrea Guzzo on 1/5/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXTextPanel.h"

@interface JMXCodePanel : JMXTextPanel
{
    NSMutableString *textBuffer;
    IBOutlet NSTextField *codeText;
}

@end
