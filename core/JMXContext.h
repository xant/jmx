//
//  JMXContext.h
//  JMX
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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
 @header JMXContext.h
 @abstract JMX Global Context
 */
#import <Cocoa/Cocoa.h>

@class JMXGraph;
@class JMXEntity;

#define USE_NSOPERATIONS 0

/*!
 @class JMXContext
 @discussion this is intended to be used as a singleton class (no constructor is provided)
             which holds references to all existing entities and signal threads
 */
@interface JMXContext : NSObject {
	NSMutableArray *registeredClasses;
#if USE_NSOPERATIONS
    NSOperationQueue *operationQueue;
#endif
@private
    NSMutableDictionary *entities;
    JMXGraph *dom;
}

/*!
 @method initialize
 @abstract Initialize the current context
 @discussion The JMXContext class is intended to be used as a singleton.
             This method should be called , instead of a constructor, 
             to initialize the singletone instance.
             The instance can later be accessed using the <code>sharedContext</code>
             class method
 */
+ (void)initialize;

@property (readonly) JMXGraph *dom;

#if USE_NSOPERATIONS
@property (readonly) NSOperationQueue *operationQueue;
+ (NSOperationQueue *)operationQueue;
#else
/*!
 @method signalThread
 @discussion this will return a pointer to a valid thread to use for signaling
 */
+ (NSThread *)signalThread;
#endif

/*!
 @method sharedContext
 @abstract get the active context object (there is only one per runtime)
 @return a valid context object
 */
+ (JMXContext *)sharedContext;
/*!
 @method registerClass:
 @param  aClass A class object which will be registered to the global context
 @abstract Register a new entity class on the active context.
           Any entity who wants to be enumerated in the library and made
           avaliable to the user, needs to register itself on the context.
           At the moment of writing this, all known entities are registered
           in JMXAppDelegate.m
 @return the active context
 */
- (void)registerClass:(Class)aClass;
/*!
 @method registeredClasses:
 @abstract Allow to query the context for all registered classes
 */
- (NSArray *)registeredClasses;
/*!
 @method allEntities:
 @abstract Allow to access all existing entities
 @return An array containing all existing entity-instances 
 */
- (NSArray *)allEntities;

- (void)addEntity:(JMXEntity *)entity;

- (void)removeEntity:(JMXEntity *)entity;

- (NSString *)dumpDOM;
@end
