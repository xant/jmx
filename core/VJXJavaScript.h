//
//  VJXJavaScript.h
//  VeeJay
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <v8.h>

using namespace v8;

@interface VJXJavaScript : NSObject {
    Persistent<Context> ctx;
}

- (void)runScript:(NSString *)source;

@end
