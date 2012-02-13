//
//  JMXKeyboardEvent.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXEvent.h"

@interface JMXKeyboardEvent : JMXEvent
{
    NSString *str;
    NSString *key;
    BOOL      ctrlKey;
    BOOL      shiftKey;
    BOOL      altKey;
    BOOL      metaKey;
    BOOL      repeat;
    NSString *locale;
}

@property (retain) NSString *str;
@property (retain) NSString *key;
@property (retain) NSString *locale;
@property (assign) BOOL      ctrlKey;
@property (assign) BOOL      shiftKey;
@property (assign) BOOL      altKey;
@property (assign) BOOL      metaKey;
@property (assign) BOOL      repeat;

@end
