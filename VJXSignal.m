//
//  VJXSignal.m
//  VeeJay
//
//  Created by xant on 9/12/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXSignal.h"

@interface VJXSignal (Private)
- (id)initWithSender:(id)theSender andData:(id)theData;
@end

@implementation VJXSignal

@synthesize sender, data;

+ (id)signalFrom:(id)sender withData:(id)data
{
    id signal = [VJXSignal alloc];
    if (signal) {
        return [[signal initWithSender:sender andData:data] autorelease];
    }
    return nil;
}

- (id)initWithSender:(id)theSender andData:(id)theData
{
    if (self = [super init]) {
        self.sender = theSender;
        self.data = theData;
    }
    return self;
}

- (void)dealloc
{
    self.sender = nil;
    self.data = nil;
    [super dealloc];
}

@end
