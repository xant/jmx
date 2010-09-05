//
//  VJXImageLayer.m
//  VeeJay
//
//  Created by Igor Sutton on 8/25/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXImageLayer.h"
#import <QTKit/QTKit.h>


@implementation VJXImageLayer

@synthesize imagePath, image;

- (id)init
{
    if (self = [super init]) {
        self.imagePath = @"/Users/xant/broken-LCD.jpg";
        self.frequency = [NSNumber numberWithDouble:1]; // override frequency
    }
    return self;
}

- (void)load
{
    NSData *imageData = [[NSData alloc] initWithContentsOfFile:self.imagePath];
    CIImage *image_ = [CIImage imageWithData:imageData];
    if (image_)
        self.image = image_;
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (!self.image)
            [self load];
        // XXX - it's useless to render the image each time ... 
        //       it should be done only if image parameters have changed
        if (self.image)
            self.currentFrame = self.image;//transformedFrame;
    }
    return [super tick:timeStamp];
}

@end
