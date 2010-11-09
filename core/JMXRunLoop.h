//
//  JMXThread.h
//  JMX
//
//  Created by xant on 10/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol JMXRunLoop
- (void)start;
- (void)stop;
- (void)tick:(uint64_t)timeStamp;
@end
