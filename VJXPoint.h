//
//  VJXPoint.h
//  VeeJay
//
//  Created by xant on 9/5/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXPoint : NSObject {
@private
    NSPoint nsPoint;
}

@property (assign) NSPoint nsPoint;

+ (id)pointWithNSPoint:(NSPoint)point;
- (id)initWithNSPoint:(NSPoint)point;
- (CGFloat)x;
- (CGFloat)y;
@end
