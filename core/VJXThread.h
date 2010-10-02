//
//  VJXThread.h
//  VeeJay
//
//  Created by xant on 10/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol VJXThread
- (void)start;
- (void)stop;
- (void)run;
// entities should implement this message to trigger 
// delivering of signals to all their custom output pins
- (void)tick:(uint64_t)timeStamp;
@end
