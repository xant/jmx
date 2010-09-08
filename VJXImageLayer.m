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
        self.imagePath = [@"~/broken-LCD.jpg" stringByExpandingTildeInPath];
        self.frequency = [NSNumber numberWithDouble:1]; // override frequency
    }
    return self;
}

- (void)load
{
    @synchronized(self) {
        NSData *imageData = [[NSData alloc] initWithContentsOfFile:self.imagePath];
        CIImage *image_ = [CIImage imageWithData:imageData];
        if (image_)
            self.image = image_;
    }
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        if (!self.image)
            [self load];
        // XXX - it's useless to render the image each time ... 
        //       it should be done only if image parameters have changed
        if (self.image) {
            CIImage *frame = self.image;
            CGRect imageRect = [frame extent];
            // scale the image to fit the layer size, if necessary
            if (size.width != imageRect.size.width || size.height != imageRect.size.height) {
                CIFilter *scaleFilter = [CIFilter filterWithName:@"CIAffineTransform"];
                float xScale = size.width / imageRect.size.width;
                float yScale = size.height / imageRect.size.height;
                // TODO - take scaleRatio into account for further scaling requested by the user
                NSAffineTransform *transform = [NSAffineTransform transform];
                [transform scaleXBy:xScale yBy:yScale];
                [scaleFilter setDefaults];
                [scaleFilter setValue:transform forKey:@"inputTransform"];
                [scaleFilter setValue:frame forKey:@"inputImage"];
                frame = [scaleFilter valueForKey:@"outputImage"];
            }
            if (currentFrame)
                [currentFrame release];
            currentFrame = [frame retain];
        }
    }
    [super tick:timeStamp];
}

@end
