//
//  VJXInputPin.h
//  VeeJay
//
//  Created by xant on 10/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXOutputPin.h"
#import "VJXPin.h"

@interface VJXInputPin : VJXPin {
    NSMutableArray      *producers;
}
@property (readonly)  NSArray *producers;

- (NSArray *)readProducers;
- (BOOL)moveProducerFromIndex:(NSUInteger)src toIndex:(NSUInteger)dst;
- (BOOL)connectToPin:(VJXOutputPin *)destinationPin;
- (void)disconnectFromPin:(VJXOutputPin *)destinationPin;
@end
