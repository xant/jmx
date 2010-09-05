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
    NSSize outputSize;

@protected
    NSArray *videoInputs;
@private
    VJXPin *imageInputPin;
    VJXPin *imageOutputPin;
    CIImage *currentFrame;
    NSMutableDictionary *imageProducers;
}

@property (assign) NSSize outputSize;

- (NSArray *)imageProducers;

@end
