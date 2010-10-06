//
//  VJXAudioScheduler.h
//  VeeJay
//
//  Created by xant on 10/3/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXAudioMixer.h"

@interface VJXAudioScheduler : VJXAudioMixer {
@private
    NSUInteger currentIndex;
    BOOL started;
}

@end
