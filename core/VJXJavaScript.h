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

using namespace v8;

@interface VJXJavaScript : NSObject {
@private
    Persistent<Context> ctx;
    std::map<id, v8::Persistent<v8::Object> > instancesMap;
}

+ (VJXJavaScript *)getContext:(Local<Context>&)currentContext;
+ (void)runScriptInBackground:(NSString *)source;
+ (void)runScript:(NSString *)source;
- (void)runScript:(NSString *)script;
- (void)addPersistentInstance:(Persistent<Object>)persistent obj:(id)obj;
- (void)removePersistentInstance:(id)obj;
@end
