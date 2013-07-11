//
//  JMXCDATA.h
//  JMX
//
//  Created by xant on 1/5/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSXMLNode+V8.h"

@interface JMXCDATA : NSXMLNode {
@private
    //BOOL _initialized;
    NSData *data;
}

@property (retain, readwrite) NSData *data;

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXCDATA);

@end
