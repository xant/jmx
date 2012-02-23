//
//  JMXImageData.h
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@class JMXUint8ClampedArray;

/*!
 @class JMXImageData
 @abstract native class to encapsulate the javascript Uint8ClampedArray interface
            (defined by the w3c specification for the canvas element) holding the image data
 */
@interface JMXImageData : NSMutableData <JMXV8>
{
    CGSize size;
    JMXUint8ClampedArray *data;
}

/*!
 @property size
 @abstract the size of the buffer (in bytes)
 */
@property (nonatomic, assign) CGSize size;
/*!
 @property width
 @abstract the width of the underlying image
 */
@property (nonatomic, readonly) CGFloat width;

/*!
 @property height
 @abstract the height of the underlying image
 */
@property (nonatomic, readonly) CGFloat height;

/*!
 @method imageDataWithImage:rect:
 @abstract convenience constructor for the image data , given a CIImage and a rect
 @param image CIImage representing the image to export
 @param rect the area of the image we want to export in the imagedata buffer
 */
+ (id)imageDataWithImage:(CIImage *)image rect:(CGRect)rect;
/*!
 @method imageDataWithData:size:
 @abstract convenience constructor for the image data, given an NSData and a CGSize
 @param data the raw data of the image
 @param size the size of the image (width/height)
 */
+ (id)imageDataWithData:(NSData *)data size:(CGSize)s;
/*!
 @method imageWithSize:
 @abstract convenience constructor for an empty image data, given a size
 */
+ (id)imageWithSize:(CGSize)s;

/*!
 @method initWithImage:rect:
 @abstract designated initializer expecting a CIImage and a CGRect
 @param image the image to encapsulate
 @param rect the area of interest
 */
- (id)initWithImage:(CIImage *)image rect:(CGRect)rect;
/*!
 @method initWithSize:
 @abstract initialize an empty data sized to store an image of the given size
 @param s the size of the new image data
 */
- (id)initWithSize:(CGSize)s;
@end
