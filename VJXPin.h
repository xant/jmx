//
//  VJXConnector.h
//  VeeJay
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef enum {
    kVJXVoidPin,
    kVJXStringPin,
    kVJXNumberPin,
    KVJXImagePin,
    KVJXAudioPin,
    kVJXPointPin,
    kVJXSizePin
} VJXPinType;

@interface VJXPin : NSObject {
@private
    VJXPinType type;
    NSString  *name;
    id         receiver;
    SEL        selector;
}

@property (readonly) VJXPinType type;
@property (readonly) NSString *name;


+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType;
+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType forObject:(id)pinReceiver withSelector:(SEL)pinSignal;

- (id)initWithName:(NSString *)name andType:(VJXPinType)pinType;
- (void)attachObject:(id)pinReceiver withSelector:(SEL)pinSignal;
- (void)signal:(id)data;
@end
