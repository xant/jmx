//
//  VJLayer.h
//  MoviePlayerD
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXLayer : NSObject {
    NSString *name;

    float saturation;
    float brightness;
    float contrast;

}

@property (nonatomic,copy) NSString *name;
@property (assign) float saturation;
@property (assign) float brightness;
@property (assign) float contrast;

- (CIImage *)frameImageForTime:(uint64_t)timeStamp;

@end
