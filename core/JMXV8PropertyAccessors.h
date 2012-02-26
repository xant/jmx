//
//  JMXV8PropertyAccessors.h
//  JMX
//
//  Created by xant on 11/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

/*!
 @header JMXV8PropertyAccessors
 @abstract pre-defined accessors to be used in V8-aware classes
 @discussion any class bound to V8 can make use of these pre-defined accessors
             to map its properties. 
             Check JMXEntity (or any of its subclasses) implmentation for an 
             example on how to make use of such accessors.
 */
#include <v8.h>
#include <map>

// TODO - setter for properties holding objects

/*!
 @function GetNumberProperty
 @abstract getter for a NSNumber property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetNumberProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetStringProperty
 @abstract getter for a NSString property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetStringProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetBoolProperty
 @abstract getter for a BOOL property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetBoolProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetIntProperty
 @abstract getter for a 32bit integer property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetIntProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetDoubleProperty
 @abstract getter for a double property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetDoubleProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetSizeProperty
 @abstract getter for a JMXSize property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetSizeProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetPointProperty
 @abstract getter for a JMXPoint property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetPointProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);
/*!
 @function GetObjectProperty
 @abstract generic getter for any NSObject-subclass property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetObjectProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);

/*!
 @function GetColorProperty
 @abstract getter for a NSColor property
 @param name the name of the property
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
v8::Handle<v8::Value>GetColorProperty(v8::Local<v8::String> name, const v8::AccessorInfo& info);

/*!
 @function SetColorProperty
 @abstract setter for a NSColor property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
 argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetColorProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);

void SetNumberProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetStringProperty
 @abstract setter for a NSString property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetStringProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetBoolProperty
 @abstract setter for a BOOL property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetBoolProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetIntProperty
 @abstract setter for a 32bit integer property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetIntProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetDoubleProperty
 @abstract setter for a double property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetDoubleProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetSizeProperty
 @abstract setter for a JMXSize property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetSizeProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);
/*!
 @function SetPointProperty
 @abstract setter for a JMXPoint property
 @param name the name of the property
 @param value the new value
 @param info extra info related to the called accessor (for instance, any eventual 
        argument passed from javascript)
 @return a v8::Handle encapsulating the return value
 */
void SetPointProperty(v8::Local<v8::String> name, v8::Local<v8::Value> value, const v8::AccessorInfo& info);


