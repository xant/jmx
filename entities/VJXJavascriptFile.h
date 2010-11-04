//
//  VJXJavascriptFile.h
//  VeeJay
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXFileRead.h"
#define __VJXV8__ 1
#import "VJXThreadedEntity.h"


@interface VJXJavascriptFile : VJXThreadedEntity <VJXFileRead> {
@private
    NSString *path;
}

@end
