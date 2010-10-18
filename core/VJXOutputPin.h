//
//  VJXOutputPin.h
//  VeeJay
//
//  Created by xant on 10/18/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXPin.h"

@class VJXInputPin;

@interface VJXOutputPin : VJXPin {
    NSMutableDictionary *receivers;

}

@property (readonly)  NSDictionary *receivers;

- (void)deliverSignal:(id)data fromSender:(id)sender;
- (void)deliverSignal:(id)data;
- (BOOL)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal;
- (void)detachObject:(id)pinReceiver;
- (BOOL)connectToPin:(VJXInputPin *)destinationPin;
- (void)disconnectFromPin:(VJXInputPin *)destinationPin;
@end
