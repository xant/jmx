//
//  VJXFileRead.h
//  VeeJay
//
//  Created by xant on 10/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol VJXFileRead
+ (NSArray *)supportedFileTypes;
- (BOOL)open:(NSString *)file;
- (void)close;
@end
