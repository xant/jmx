//
//  JMXUint8ClampedArray.h
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@interface JMXUint8ClampedArray : NSObject <JMXV8>
{
    uint8_t *buffer;
    size_t size;
    BOOL copy;
    BOOL mustFreeOnRelease;
}

@property (readonly) uint8_t *buffer;

+ (id)uint8ClampedArrayWithBytes:(uint8_t *)bytes length:(size_t)length;

+ (id)uint8ClampedArrayWithBytesNoCopy:(uint8_t *)bytes
                                length:(size_t)length
                         freeOnRelease:(BOOL)freeOnRelease;


- (id)initWithBytes:(uint8_t *)bytes length:(size_t)length;

- (id)initWithBytesNoCopy:(uint8_t *)bytes
                   length:(size_t)length
            freeOnRelease:(BOOL)freeOnRelease;

@end