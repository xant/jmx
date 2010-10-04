//
//  VJXAudioScheduler.h
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"
#import "VJXPin.h"

@interface VJXAudioScheduler : VJXThreadedEntity {
@private
    VJXPin *startPin;
    VJXPin *stopPin;
    NSUInteger currentIndex;
    BOOL started;
}

@end
