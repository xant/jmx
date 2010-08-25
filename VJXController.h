//
//  VJController.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXMovieLayer.h"

@interface VJXController : NSObject {
    NSMutableArray *layers;
    NSMutableArray *outputs;

    NSThread *worker;

    CIImage *lastImage;
    uint64_t previousTimeStamp;

}

@property (nonatomic, retain) CIImage *lastImage;
@property (nonatomic, retain) NSMutableArray *layers;
@property (nonatomic, retain) NSMutableArray *outputs;

- (CIImage *)frameImageForTime:(uint64_t)timeStamp;
- (void)nextFrame:(id)userInfo;
- (IBAction)start:(id)sender;
- (IBAction)stop:(id)sender;

- (void)addOutput:(id)output;

@end
