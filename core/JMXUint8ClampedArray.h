//
//  JMXUint8ClampedArray.h
//  JMX
//
//  Created by Andrea Guzzo on 1/30/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXByteArray.h"

@interface JMXUint8ClampedArray : JMXByteArray
{
}

+ (id)uint8ClampedArrayWithBytes:(uint8_t *)bytes length:(size_t)length;

+ (id)uint8ClampedArrayWithBytesNoCopy:(uint8_t *)bytes
                                length:(size_t)length
                         freeOnRelease:(BOOL)freeOnRelease;

@end