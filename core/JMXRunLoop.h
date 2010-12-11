//
//  JMXThread.h
//  JMX
//
//  Created by xant on 10/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXRunLoop.h
 @abstract define a formal protocol for entities implementing a runloop
 */

#import <Cocoa/Cocoa.h>

/*!
 @protocol JMXRunLoop
 @abstract formal protocol for entities implementing a runloop (like JMXThreadEntity and subclasses)
 */
@protocol JMXRunLoop
/*!
 @method start
 @abstract start the runloop
 */
- (void)start;
/*!
 @method stop
 @abstract stop the runloop
 */
- (void)stop;
/*!
 @method tick:
 @param timeStamp the timeStamp to which this tick call refers to
 @abstract this method will be called at a certain frequency during the thread runloop
           timeStamp will indicate when the runloop called the method and can be used to 
           determine what must be delivered on output pins
           TODO - write examples
 */

- (void)tick:(uint64_t)timeStamp;
@end
