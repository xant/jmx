//
//  VJXSeekable.h
//  VeeJay
//
//  Created by xant on 10/6/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define VJX_SEEK_BEGIN 0
#define VJX_SEEK_END 1

@protocol VJXSeekable
- (BOOL)seekTo:(NSUInteger)offest;
- (NSUInteger)tellOffest;
- (NSUInteger)totalLength;
@end
