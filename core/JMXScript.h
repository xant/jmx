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

@class JMXScriptEntity;
@class JMXEvent;
@class JMXEventListener;
@class JMXScriptTimer;

/*!
 @class JMXScript
 @abstract Core class taking care of managing V8 execution contextes 
 */
@interface JMXScript : NSObject {
@private
    JMXScriptEntity *scriptEntity;
    v8::Persistent<v8::Context> ctx;
    //std::map<id, v8::Persistent<v8::Object> > instancesMap;
    NSMutableDictionary *persistentInstances;
    NSMutableSet *runloopTimers;
    NSOperationQueue *operationQueue;
    NSTimer *nodejsRunTimer;
    NSMutableDictionary *eventListeners;
    BOOL started;
}

/*!
 @property scriptEntity
 @abstract JMXScriptEntity instance bound to the javascript global context being executed
 @discussion the global script entity, if defined, allows exporting input/output pins to the board
             and actually reporesents a bridge between the graph created inside the script itself 
             and the main graph managed through the board
 */
@property (readonly, nonatomic) JMXScriptEntity *scriptEntity;
@property (readonly, nonatomic) NSSet *runloopTimers;
@property (readonly, nonatomic) NSDictionary *eventListeners;
@property (readonly) v8::Persistent<v8::Context> ctx;

/*!
 @method getContext:
 @abstract get the JMXScript instance where the provided currentContext is being managed/executed
 @param currentContext reference to a Local<Context> where to store the pointer to the current context
 @return the JMXScript instance holding currentContext
 */
+ (JMXScript *)getContext;

- (void)startWithEntity:(JMXScriptEntity *)entity;

/*!
 @method runScriptInBackground:
 @abstract run a script in a detached thread using a new (autoreleased) JMXScript instace
 @param source an NSString holding the javascript sourcecode
 */
+ (void)runScriptInBackground:(NSString *)source;

/*!
 @method runScript:
 @abstract run a script in the current thread using a new (autoreleased) JMXScript instace 
 @param source an NSString holding the javascript sourcecode
 */
+ (BOOL)runScript:(NSString *)source;

/*!
 @method runScript:
 @abstract run a script in the current thread
 @param source an NSString holding the javascript sourcecode
 */
- (BOOL)runScript:(NSString *)source;

/*!
 @method addPersistentInstance:obj
 @abstract add a new persistent instance to the internal map
 @param persistent the new Persistent<Object> in the javascript context
 @param obj the native obj-c instance bound to the persistent object
 @discussion * TODO *
 */

- (void)execCode:(NSString *)code;
- (void)execFunction:(v8::Handle<v8::Function>)function;
- (v8::Handle<v8::Value>)execFunction:(v8::Handle<v8::Function>)function
       withArguments:(v8::Handle<v8::Value> *)argv
               count:(NSUInteger)count;
- (void)addPersistentInstance:(v8::Persistent<v8::Object>)persistent obj:(id)obj;
/*!
 @method removePersistentInstance:
 @abstract remove a persistent instance from the internal map
 @param obj the native obj-c instance bound to the persistent instance we want to remove
 @discussion * TODO *
 */
- (void)removePersistentInstance:(id)obj;
- (v8::Handle<v8::Value>)getPersistentInstance:(id)obj;
- (void)clearTimers;

- (void)addRunloopTimer:(JMXScriptTimer *)timer;
- (void)removeRunloopTimer:(JMXScriptTimer *)timer;
- (void)addListener:(JMXEventListener *)listener forEvent:(NSString *)event;
- (void)removeListener:(JMXEventListener *)listener forEvent:(NSString *)event;
- (BOOL)dispatchEvent:(JMXEvent *)event;
- (BOOL)dispatchEvent:(JMXEvent *)anEvent toTarget:(NSXMLNode *)aTarget;

@end
