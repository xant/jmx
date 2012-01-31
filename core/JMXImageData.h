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

@interface JMXImageData : NSMutableData <JMXV8>
{
    CGSize size;
    JMXUint8ClampedArray *data;
}

@property (nonatomic, assign) CGSize size;
@property (nonatomic, readonly) CGFloat width;
@property (nonatomic, readonly) CGFloat height;

+ (id)imageDataWithImage:(CIImage *)image rect:(CGRect)rect;
+ (id)imageDataWithData:(NSData *)data size:(CGSize)s;
+ (id)imageWithSize:(CGSize)s;
- (id)initWithImage:(CIImage *)image rect:(CGRect)rect;
- (id)initWithSize:(CGSize)s;
@end
