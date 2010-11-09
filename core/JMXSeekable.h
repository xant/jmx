//
//  JMXSeekable.h
//  JMX
//
//  Created by xant on 10/6/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


#define JMX_SEEK_BEGIN 0
#define JMX_SEEK_END 1

@protocol JMXSeekable
- (BOOL)seekTo:(NSUInteger)offest;
- (NSUInteger)tellOffest;
- (NSUInteger)totalLength;
@end
