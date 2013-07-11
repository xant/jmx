//
//  JMXByteArray.h
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXV8.h"

@interface JMXByteArray : NSObject <JMXV8>
{
    uint8_t *buffer;
    size_t  size;
    BOOL copy;
    BOOL mustFreeOnRelease;
}

@property (readonly) uint8_t *buffer;
@property (readonly) size_t size;

+ (id)byteArrayWithBytes:(uint8_t *)bytes length:(size_t)length;

+ (id)byteArrayWithBytesNoCopy:(uint8_t *)bytes
                        length:(size_t)length
                 freeOnRelease:(BOOL)freeOnRelease;


- (id)initWithBytes:(uint8_t *)bytes length:(size_t)length;

- (id)initWithBytesNoCopy:(uint8_t *)bytes
                   length:(size_t)length
            freeOnRelease:(BOOL)freeOnRelease;

- (uint8_t)byteAtIndex:(NSInteger)index;
@end
