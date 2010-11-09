//
//  JMXJavascriptFile.h
//  JMX
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXFileRead.h"
#define __JMXV8__ 1
#import "JMXThreadedEntity.h"


@interface JMXJavascriptFile : JMXThreadedEntity <JMXFileRead> {
@private
    NSString *path;
}

@end
