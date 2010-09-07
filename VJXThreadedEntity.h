/*
 *  VJXThreadedEntity.h
 *  VeeJay
 *
 *  Created by xant on 9/7/10.
 *  Copyright 2010 Dyne.org. All rights reserved.
 *
 */

#import "VJXEntity.h"

//@interface VJXThreadedEntity : VJXEntity <VJXThread> {
@interface VJXThreadedEntity : VJXEntity {
@private
    NSThread *worker;

}
- (void)start;
- (void)stop;
- (void)run;
// entities should implement this message to trigger 
// delivering of signals to all their custom output pins
- (void)tick:(uint64_t)timeStamp;
@end