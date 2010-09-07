//
//  VJLayer.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

@interface VJXLayer : VJXThreadedEntity {
@protected
    NSNumber *saturation;
    NSNumber *brightness;
    NSNumber *contrast;
    NSNumber *alpha;
    NSNumber *rotation;
    NSNumber *scaleRatio;
    NSNumber *fps;
    VJXPoint *origin;
    VJXSize  *size;
    
    CIImage *currentFrame;
    VJXPin *outputFramePin;

@private

}


@property (retain) NSNumber *alpha;
@property (retain) NSNumber *saturation;
@property (retain) NSNumber *brightness;
@property (retain) NSNumber *contrast;
@property (retain) NSNumber *rotation;
@property (retain) NSNumber *scaleRatio;
@property (retain) NSNumber *fps;
@property (retain) VJXPoint *origin;
@property (retain) VJXSize  *size;
@property (readonly) CIImage *currentFrame;

@end
