//
//  VJXThread.h
//  VeeJay
//
//  Created by xant on 9/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"

@interface VJXEntity (Threaded)
    - (void)start;
    - (void)stop;
    - (void)run;
@end
