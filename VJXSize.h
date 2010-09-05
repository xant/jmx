//
//  VJXSize.h
//  VeeJay
//
//  Created by xant on 9/5/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXSize : NSObject {
@private
    NSSize nsSize;
}

@property (assign) NSSize nsSize;

+ (id)sizeWithNSSize:(NSSize)size;
- (id)initWithNSSize:(NSSize)size;
- (CGFloat)width;
- (CGFloat)height;

@end
