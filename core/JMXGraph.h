//
//  JMXGraph.h
//  JMX
//
//  Created by xant on 1/1/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface JMXGraph : NSXMLDocument {
    NSString *uid;
    NSXMLNode *headNode;
}

@property (readonly) NSString *uid;
@property (readonly) NSXMLNode *headNode;

@end
