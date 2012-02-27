//
//  NSDictionary+V8.h
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@interface NSDictionary (JMXV8)

- (v8::Handle<v8::Object>)jsObj;

@end
