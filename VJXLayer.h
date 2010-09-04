//
//  VJLayer.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"


@interface VJXLayer : VJXEntity {
@protected
    NSNumber *saturation;
    NSNumber *brightness;
    NSNumber *contrast;
    NSNumber *alpha;
    NSNumber *rotation;
    NSNumber *scaleRatio;
    NSNumber *fps;
    NSPoint  origin;
    NSSize   size;
    
    BOOL active;
    
    CIImage *currentFrame;
    uint64_t previousTimeStamp;
    VJXPin *outputFramePin;

@private
    NSThread *worker;

}

- (void)start;
- (void)stop;
- (void)run;

@property (retain) NSNumber *alpha;
@property (retain) NSNumber *saturation;
@property (retain) NSNumber *brightness;
@property (retain) NSNumber *contrast;
@property (retain) NSNumber *rotation;
@property (retain) NSNumber *scaleRatio;
@property (assign) NSPoint origin;
@property (assign) NSSize size;
@property (retain) NSNumber *fps;
@property (retain) CIImage *currentFrame;

@property (assign) BOOL active;

- (CIImage *)frameImageForTime:(uint64_t)timeStamp;

@end
