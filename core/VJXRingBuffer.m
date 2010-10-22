//
//  VJXRingBuffer.m
//  VeeJay
//
//  Created by xant on 10/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXRingBuffer.h"

@implementation VJXRingBuffer

@synthesize size;

+ (id)ringBufferWithSize:(UInt64)size
{
    VJXRingBuffer *obj = [VJXRingBuffer alloc];
    if (obj)
        return [[obj initWithSize:size] autorelease];
    return nil;
}

- (void)dealloc
{
    if (buf)
        free(buf);
    [super dealloc];
}
- (id)initWithSize:(UInt64)_size;
{
    self = [super init];
    if (self) {
        size = _size + 1;;
        buf = malloc(size);
        if(!buf)
            return nil;
    }
    return self;
}

- (void)skip:(UInt64)_size
{
    if(_size >= size) { // just empty the ringbuffer
        rfx = wfx;
    } else {
        if (_size > size-rfx) {
            _size -= size-rfx;
            rfx = _size;
        } else {
            rfx+=_size;
        }
    }
    
}
- (NSData *)read:(UInt64)_size
{
    UInt64 read_size = [self length]; // never read more than available data
    UInt64 to_end = size - rfx;
    UInt8 *out = NULL;
    NSData *data = nil;
    // requested size is less than stored data, return only what has been requested
    if(read_size > _size)
        read_size = _size;
    
    if(read_size > 0) {
        out = malloc(read_size);
        // if the write pointer is beyond the read pointer or the requested read_size is 
        // smaller than the number of octets between the read pointer and the end of the buffer,
        // than we can safely copy all the octets in a single shot
        if(wfx > rfx || to_end >= read_size) {
            memcpy(out, &buf[rfx], read_size);
            rfx += read_size;
        }
        else { // otherwise we have to wrap around the buffer and copy octest in two times
            memcpy(out, &buf[rfx], to_end);
            memcpy(out+to_end, &buf[0], read_size - to_end);
            rfx = read_size - to_end;
        }
    }
    if (out)
        data = [NSData dataWithBytesNoCopy:out length:read_size freeWhenDone:YES];
    return data;
}

- (UInt64)write:(UInt8 *)input size:(UInt64)_size
{
    UInt64 write_size = size-[self length]-1; // don't write more than available size
    
    if(!input || !_size) // safety belt
        return 0;
    // if requested size fits the available space, use that
    if(write_size > _size)
        write_size = _size;
    
    if(wfx >= rfx) { // write pointer is ahead
        if(write_size <= size - wfx) {
            memcpy(&buf[wfx], input, write_size);
            wfx+=write_size;
        } else { // and we have to wrap around the buffer 
            UInt64 to_end = size - wfx;
            memcpy(&buf[wfx], input, to_end);
            memcpy(buf, input+to_end, write_size - to_end);
            wfx = write_size - to_end;
        }
    } else { // read pointer is ahead we can safely memcpy the entire chunk
        memcpy(&buf[wfx], input, write_size);
        wfx+=write_size;
    }
    return write_size;
    
}
- (UInt64)length
{
    if(wfx == rfx)
        return 0;
    if(wfx < rfx)
        return wfx+(size-rfx);
    return wfx-rfx;
}

- (UInt64)find:(UInt8)octet
{
    UInt64 i;
    UInt64 to_read = [self length];
    if (to_read == 0)
        return -1; // XXX
    
    if(wfx > rfx) {
        for (i = rfx; i < wfx; i++) {
            if(buf[i] == octet)
                return(i-rfx);
        }
    } else {
        for (i = rfx; i < size; i++) {
            if(buf[i] == octet)
                return(i-rfx);
        }
        for (i = 0; i < wfx; i++) {
            if(buf[i] == octet)
                return((size-rfx)+i);
        }
    }
    return -1; // XXX
}

- (NSData *)readUntil:(UInt8)octet maxSize:(UInt64)maxsize
{
    UInt64 i;
    UInt64 total_size = [self length];
    UInt64 to_read = total_size;
    UInt64 found = 0;
    char *out = malloc(maxsize);
    for (i = rfx; i < total_size; i++) {
        to_read--;
        if(buf[i] == octet)  {
            found = 1;
            break;
        } else if ((total_size-to_read) == maxsize) {
            break;
        } else {
            out[i] = buf[i];
        }
    }
    if(!found) {
        for (i = 0; to_read > 0 && (total_size-to_read) < maxsize; i++) {
            to_read--;
            if(buf[i] == octet) {
                found = 1;
                break;
            }
            else {
                out[i] = buf[i];
            }
            
        }
    }
    [self skip:(total_size - to_read)];
    NSData *data = [NSData dataWithBytesNoCopy:out length:(total_size-to_read) freeWhenDone:YES];
    return data;
    
}

- (void)clear
{
    rfx = wfx = 0;
}

- (NSString *)hexDump
{
    return nil;
}

@end;