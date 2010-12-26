//
// JMXThreadedEntity.h
// JMX
//
// Created by xant on 9/7/10.
// Copyright 2010 Dyne.org. All rights reserved.
//
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//
/*!
 @header JMXThreadedEntity.h
 @abstract Base (abstract) class representing a threaded entity in the JMX world
 @discussion Threaded entities are those which require an active runloop to let them produce
             a signal at a given frequency. Not all entities need to be threaded, consider
             subclassing JMXEntity instead of this class if you don't really need an active thread
             to drive production of output signals
 @related JMXPin.h
 */
#import "JMXEntity.h"
#import "JMXRunLoop.h"

@interface JMXEntity (Threaded)
/*!
 @property frequency
 @abstract get/set the frequency at which output signals are delivered
 @discussion the frequency affects also how intensively is the runloop 
 */
@property (readwrite, copy) NSNumber *frequency;
@property (readwrite, assign) BOOL quit;
@property (readonly) uint64_t previousTimeStamp;
// entities should implement this message to trigger 
// delivering of signals to all their custom output pins
- (void)tick:(uint64_t)timeStamp;
- (void)start;
- (void)stop;
#ifdef __JMXV8__
+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate;
#endif
@end

/*!
 * @class JMXThreadedEntity
 * @abstract Encapsulates an entity in a new thread. the 'tick' message will be periodically sent to the encapsulated entity
 * @discussion conforms to protocols: JMXRunLoop
 *
 *
 * This class exposes the follwing input pins:
 * 
 * * active kJMXBooleanPin
 * 
 * * frequency kJMXNumberPin MinValue:1.0 MaxValue:120.0
 *             The frequency at which signals must be delivered (AKA: how many times the tick: message is sent to the instance) 
 * 
 *
 * This class exposes the follwing output pins:
 *
 * * frequency kJMXNumberPin
 *             The effective frequency at which the entity is running (could be slowed down by a too heavy tick implementation)
 * 
 */
@interface JMXThreadedEntity : NSProxy < JMXRunLoop > {
@protected
    uint64_t previousTimeStamp;
@private
    NSThread *worker;
    NSTimer  *timer;
    int64_t stamps[kJMXFpsMaxStamps + 1]; // XXX - 25 should be a constant
    int stampCount;
    JMXEntity *realEntity;
    NSNumber *frequency;
    BOOL quit;
    JMXOutputPin  *frequencyPin;
}
@property (readwrite, retain) NSNumber *frequency;
@property (readonly) JMXEntity *realEntity;
@property (readwrite, assign) uint64_t previousTimeStamp;
@property (readwrite, assign) BOOL quit;

+ threadedEntity:(JMXEntity *)entity;
- initWithEntity:(JMXEntity *)entity;
// entities should implement this message to trigger 
// delivering of signals to all their custom output pins
- (void)tick:(uint64_t)timeStamp;
- (void)start;
- (void)stop;
@end
