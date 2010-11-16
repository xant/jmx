//
//  JMXScript.h
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "JMXV8PropertyAccessors.h"

@class JMXEntity;

@interface JMXScript : NSObject {
@private
    JMXEntity *scriptEntity;
    v8::Persistent<v8::Context> ctx;
    std::map<id, v8::Persistent<v8::Object> > instancesMap;
}

@property (readonly, nonatomic) JMXEntity *scriptEntity;

+ (JMXScript *)getContext:(v8::Local<v8::Context>&)currentContext;
+ (void)runScriptInBackground:(NSString *)source;
+ (void)runScriptInBackground:(NSString *)source withEntity:(JMXEntity *)entity;
+ (void)runScript:(NSString *)source;
+ (void)runScript:(NSString *)source withEntity:(JMXEntity *)entity;
- (void)runScript:(NSString *)source;
- (void)runScript:(NSString *)source withEntity:(JMXEntity *)entity;
- (void)addPersistentInstance:(v8::Persistent<v8::Object>)persistent obj:(id)obj;
- (void)removePersistentInstance:(id)obj;
@end
