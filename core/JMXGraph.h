//
//  JMXGraph.h
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSXMLNode+V8.h"


@interface JMXGraph : NSXMLDocument {
    NSString *uid;
}

@property (readonly) NSString *uid;

@end
