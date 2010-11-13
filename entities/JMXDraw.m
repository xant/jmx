//
//  JMXDrawing.m
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXDraw.h"


@implementation JMXDraw

- (id)init
{
    self = [super init];
    if (self) {
        drawPath = [[JMXDrawPath alloc] initWithFrameSize:self.size];
    }
    return self;
}

- (void)dealloc
{
    [drawPath release];
    [super dealloc];
}

/* TODO - accessors to JMXDrawPath methods */

- (void)tick:(uint64_t)timeStamp
{
    [outputFramePin deliverData:drawPath.currentFrame];
    [super tick:timeStamp];
}

/* TODO - javascript BINDINGS */

@end
