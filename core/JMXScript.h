//
//  JMXScript.h
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXScript.h
 @abstract Core implementation of V8 bindings
 */
#import <Cocoa/Cocoa.h>
#include "JMXV8PropertyAccessors.h"

@class JMXEntity;

/*!
 @class JMXScript
 @abstract Core class taking care of managing V8 execution contextes 
 */
@interface JMXScript : NSObject {
@private
    JMXEntity *scriptEntity;
    v8::Persistent<v8::Context> ctx;
    std::map<id, v8::Persistent<v8::Object> > instancesMap;
}

/*!
 @property scriptEntity
 @abstract JMXEntity subclass bound to the javascript global context being executed
 @discussion the global script entity, if defined, allows exporting input/output pins to the board
             and actually reporesents a bridge between the graph created inside the script itself 
             and the main graph managed through the board
 */
@property (readonly, nonatomic) JMXEntity *scriptEntity;

/*!
 @method getContext:
 @abstract get the JMXScript instance where the provided currentContext is being managed/executed
 @param currentContext reference to a Local<Context> where to store the pointer to the current context
 @return the JMXScript instance holding currentContext
 */
+ (JMXScript *)getContext:(v8::Local<v8::Context>&)currentContext;
/*!
 @method runScriptInBackground:
 @abstract run a script in a detached thread using a new (autoreleased) JMXScript instace
 @param source an NSString holding the javascript sourcecode
 */
+ (void)runScriptInBackground:(NSString *)source;
/*!
 @method runScriptInBackground:
 @abstract run a script in a detached thread using a new (autoreleased) JMXScript instace
 @param source an NSString holding the javascript sourcecode
 @param entity the script entity to be bound to the execution context
 */
+ (void)runScriptInBackground:(NSString *)source withEntity:(JMXEntity *)entity;
/*!
 @method runScript:
 @abstract run a script in the current thread using a new (autoreleased) JMXScript instace 
 @param source an NSString holding the javascript sourcecode
 */
+ (void)runScript:(NSString *)source;
/*!
 @method runScript:withEntity:
 @abstract run a script in the current thread using a new (autoreleased) JMXScript instace
 @param source an NSString holding the javascript sourcecode
 @param entity the script entity to be bound to the execution context
 */
+ (void)runScript:(NSString *)source withEntity:(JMXEntity *)entity;
/*!
 @method runScript:
 @abstract run a script in the current thread
 @param source an NSString holding the javascript sourcecode
 */
- (void)runScript:(NSString *)source;
/*!
 @method runScript:withEntity:
 @abstract run a script in the current thread
 @param source an NSString holding the javascript sourcecode
 @param entity the script entity to be bound to the execution context
 */
- (void)runScript:(NSString *)source withEntity:(JMXEntity *)entity;
/*!
 @method addPersistentInstance:obj
 @abstract add a new persistent instance to the internal map
 @param persistent the new Persistent<Object> in the javascript context
 @param obj the native obj-c instance bound to the persistent object
 @discussion * TODO *
 */
- (void)addPersistentInstance:(v8::Persistent<v8::Object>)persistent obj:(id)obj;
/*!
 @method removePersistentInstance:
 @abstract remove a persistent instance from the internal map
 @param obj the native obj-c instance bound to the persistent instance we want to remove
 @discussion * TODO *
 */
- (void)removePersistentInstance:(id)obj;
@end
