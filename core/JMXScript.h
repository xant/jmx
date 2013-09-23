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
    NSMutableDictionary *eventListeners;
    //BOOL started;
}

/*!
 @property scriptEntity
 @abstract JMXScriptEntity instance bound to the javascript global context being executed
 @discussion the global script entity, if defined, allows exporting input/output pins to the board
             and actually reporesents a bridge between the graph created inside the script itself 
             and the main graph managed through the board
 */
@property (readonly, nonatomic) JMXScriptEntity *scriptEntity;

/*!
 @property runloopTimers
 @abstract NSSet holding all timers registered in this script runloop.
           Note: only timers added using the global.addToRunLoop() method are being listed here  
 */
@property (readonly, nonatomic) NSSet *runloopTimers;
/*!
 @property eventListeners
 @abstract dictionary holding all registered eventListeners in this js context.
           The key of the dictionary is the event type and the value for each key is a 
           NSSet holding all the listeners for that specific event
 */
@property (readonly, nonatomic) NSDictionary *eventListeners;

/*!
 @property ctx
 @abstract the global JS context
 */
@property (readonly) v8::Persistent<v8::Context> ctx;

/*!
 @method getContext:
 @abstract get the JMXScript instance where the provided currentContext is being managed/executed
 @return the JMXScript instance holding currentContext
 */
+ (JMXScript *)getContext;

/*!
 @method startWithEntity:
 @abstract start this javascript context binding it to the provided JMXScriptEntity
 */
- (void)startWithEntity:(JMXScriptEntity *)entity;

/*!
 @method stop
 @abstract stop the execution of this JS context and reclaim all persistent instances created while the context running
 */
- (void)stop;

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
 @method runScript:withArgs:
 @abstract run a script in the current thread providing arguments (TODO : elaborate)
 @param source NSString holding the javscript sourcecode
 @param args NSArray holding arguments which will be available to the script
 */
- (BOOL)runScript:(NSString *)source withArgs:(NSArray *)args;

/*!
 @method execCode:
 @abstract Interpret and exec the provided javascript code in this JS Context
 */
- (BOOL)execCode:(NSString *)code;

/*!
 @method execFunction:
 @abstract exec the provided javascript function in this JS context
 */
- (BOOL)execFunction:(v8::Handle<v8::Function>)function;

/*!
 @method execFunction:WithArguments:count
 @abstract exec the javascript function, passing the provided arguments, in this JS Context
 */
- (v8::Handle<v8::Value>)execFunction:(v8::Handle<v8::Function>)function
       withArguments:(v8::Handle<v8::Value> *)argv
               count:(NSUInteger)count;

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

/*!
 @method getPersistentInstance:
 @abstract get the v8 persistent instance bound to the provided objC object instance
 @param obj the native obj-c instance for which we want to obtain the v8 persistent instance
 */
- (v8::Handle<v8::Value>)getPersistentInstance:(id)obj;

/*!
 @method clearTimers
 @abstract clear all timers registered to this JS context
 */
- (void)clearTimers;

/*!
 @method addRunLoopTimer:
 @abstract add a new timer to the current runloop for this JS context
 @param timer the timer to add
 */
- (void)addRunloopTimer:(JMXScriptTimer *)timer;
/*!
 @method removeRunloopTimer:
 @abstract remove the timer from the current runloop
 @param timer the timer to remove
 */
- (void)removeRunloopTimer:(JMXScriptTimer *)timer;
/*!
 @method addListener:forEvent:
 @abstract add a new listener for the specified event
 @param listener the new listener
 @param event the event to track
 */
- (void)addListener:(JMXEventListener *)listener forEvent:(NSString *)event;
/*!
 @method removeListener:forEvent:
 @abstract remove an existing listener tracking a specific event
 @param listener the listener to remove
 @param event the event tracked by the listener we want to remove
 */
- (void)removeListener:(JMXEventListener *)listener forEvent:(NSString *)event;
/*!
 @method dispatchEvent:
 @abstract dispatch an event to all registered listener
 @param event the event to dispatch
 */
- (BOOL)dispatchEvent:(JMXEvent *)event;
/*!
 @method dispatchEvent:toTarget:
 @abstract dispatch an event to a specific target
 @param event the event to dispatch
 @param target the target to send the event to
 */
- (BOOL)dispatchEvent:(JMXEvent *)event toTarget:(NSXMLNode *)target;

@end
