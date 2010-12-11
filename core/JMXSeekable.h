//
//  JMXSeekable.h
//  JMX
//
//  Created by xant on 10/6/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
/*!
 @header JMXSeekable.h
 @abstract protocol for seekable entities
 */
#import <Cocoa/Cocoa.h>


#define JMX_SEEK_BEGIN 0
#define JMX_SEEK_END 1


/*!
 @protocol JMXSeekable
 @discussion Any entity which supports seek should conform to this protocol
             to allow the engine to access the functionality
 */
@protocol JMXSeekable
/*!
 @method seekTo:
 @abstract set the offset for next read/write operations
 @param offset the offset to seek to
 @return YES if success, NO otherwise
 */
- (BOOL)seekTo:(NSUInteger)offset;
/*!
 @method tellOffset
 @abstract get the actual offset
 @return the actually offset
 */
- (NSUInteger)tellOffest;
/*!
 @method totalLength
 @abstract get the totalLength of the media
 @return the total length of the media (AKA: how far it's possible to seek)
 */
- (NSUInteger)totalLength;
@end
