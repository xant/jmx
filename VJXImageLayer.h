//
//  VJXImageLayer.h
//  VeeJay
//
//  Created by Igor Sutton on 8/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXLayer.h"

@interface VJXImageLayer : VJXLayer {
@private
    CIImage *image;
    NSString *imagePath;
}

@property (nonatomic,retain) CIImage *image;
@property (nonatomic,copy) NSString *imagePath;

@end
