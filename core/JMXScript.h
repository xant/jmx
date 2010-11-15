//
//  JMXScript.h
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <v8.h>
#include <map>

v8::Handle<v8::Value>GetNumberProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetStringProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetBoolProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetIntProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetDoubleProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetSizeProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetObjectProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);


void SetNumberProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetStringProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetBoolProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetIntProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetDoubleProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetSizeProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);

// TODO - setter for properties holding objects

//using namespace v8;

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
