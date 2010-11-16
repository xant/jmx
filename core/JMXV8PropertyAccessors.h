//
//  JMXV8PropertyAccessors.h
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#include <v8.h>
#include <map>

// TODO - setter for properties holding objects

v8::Handle<v8::Value>GetNumberProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetStringProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetBoolProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetIntProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetDoubleProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetSizeProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetPointProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
v8::Handle<v8::Value>GetObjectProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);

void SetNumberProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetStringProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetBoolProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetIntProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetDoubleProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetSizeProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
void SetPointProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);


