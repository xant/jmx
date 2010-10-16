//
//  VJXRingBuffer.h
//  VeeJay
//
//  Created by xant on 10/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXRingBuffer : NSObject {
@private
    UInt8 *buf;        // the buffer
    UInt64 size;           // buffer size
    UInt64 rfx;            // read offset
    UInt64 wfx;            // write offset
}

@property (readonly)UInt64 size;

+ (id)ringBufferWithSize:(UInt64)size;
- (id)initWithSize:(UInt64)size;
- (void)skip:(UInt64)size;
- (NSData *)read:(UInt64)size;
- (UInt64)write:(UInt8 *)input size:(UInt64)size;
- (UInt64)length;
- (UInt64)find:(UInt8)octet;
- (NSData *)readUntil:(UInt8)octet maxSize:(UInt64)maxsize;
- (void)clear;
- (NSString *)hexDump;

@end
