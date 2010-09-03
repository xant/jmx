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
    kVJXImagePin,
    kVJXAudioPin,
    kVJXPointPin,
    kVJXSizePin
} VJXPinType;

@interface VJXPin : NSObject {
@private
    VJXPinType type;
    NSString  *name;
    NSMutableDictionary *receivers;
    BOOL       multiple;
}

@property (readonly) VJXPinType type;
@property (readonly) NSString *name;
@property (readonly) BOOL multiple;



+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType;
+ (id)pinWithName:(NSString *)name andType:(VJXPinType)pinType forObject:(id)pinReceiver withSelector:(NSString *)pinSignal;

- (id)initWithName:(NSString *)name andType:(VJXPinType)pinType;
- (void)attachObject:(id)pinReceiver withSelector:(NSString *)pinSignal;
- (void)deliverSignal:(id)data fromSender:(id)sender;
- (void)deliverSignal:(id)data;
- (void)allowMultipleConnections:(BOOL)choice;
@end
