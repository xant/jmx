//
//  VJXMixer.h
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"


@interface VJXMixer : VJXEntity {
@public
    int fps;
@protected
    NSArray *videoInputs;
@private
    VJXPin *imageInputPin;
    VJXPin *imageOutputPin;
    CIImage *currentFrame;
    NSThread *worker;
    uint64_t previousTimeStamp;
    NSMutableDictionary *inputStats;
}

@property (assign) int fps;

- (void)start;
- (void)stop;
- (void)run;

@end
