//
//  JMXImageElement.h
//  JMX
//
//  Created by xant on 1/18/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXElement.h"

@interface JMXImageElement : JMXElement {
@protected
    NSString *alt;
    NSString *src;
    NSString *useMap;
    BOOL isMap;
    NSUInteger width;
    NSUInteger height;
    NSUInteger naturalWidth;
    NSUInteger naturalHeight;
    BOOL complete;
}

@property (readwrite, copy) NSString *alt;
@property (readwrite, copy) NSString *src;
@property (readwrite, copy) NSString *useMap;
@property (readwrite, assign) BOOL isMap;
@property (readwrite, assign) NSUInteger width;
@property (readwrite, assign) NSUInteger height;
@property (readonly) NSUInteger naturalWidth;
@property (readonly) NSUInteger naturalHeight;
@property (readonly) BOOL complete;

@end

JMXV8_DECLARE_CONSTRUCTOR(JMXImageElement);

