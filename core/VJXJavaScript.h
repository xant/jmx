//
//  VJXJavaScript.h
//  VeeJay
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <v8.h>
#include <map>

v8::Handle<v8::Value>accessStringProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>accessNumberProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>accessBoolProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);

//using namespace v8;

@class VJXEntity;

@interface VJXJavaScript : NSObject {
@private
    VJXEntity *scriptEntity;
    v8::Persistent<v8::Context> ctx;
    std::map<id, v8::Persistent<v8::Object> > instancesMap;
}

+ (VJXJavaScript *)getContext:(v8::Local<v8::Context>&)currentContext;
+ (void)runScriptInBackground:(NSString *)source;
+ (void)runScript:(NSString *)source;
+ (void)runScript:(NSString *)source withEntity:(VJXEntity *)entity;
- (void)runScript:(NSString *)source;
- (void)runScript:(NSString *)source withEntity:(VJXEntity *)entity;
- (void)addPersistentInstance:(v8::Persistent<v8::Object>)persistent obj:(id)obj;
- (void)removePersistentInstance:(id)obj;
@end
