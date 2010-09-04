//
//  VJXObject.h
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXPin.h"

@interface VJXEntity : NSObject <NSCopying> {
@public
    NSString *name;

@protected
    NSMutableArray *inputPins;
    NSMutableArray *outputPins;
    
@private
    
}

- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType;
- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector;

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType;
- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector;

- (VJXPin *)inputPinWithName:(NSString *)pinName;
- (VJXPin *)outputPinWithName:(NSString *)pinName;

- (void)signalOutput:(id)data;


@property (readonly) NSMutableArray *inputPins;
@property (readonly) NSMutableArray *outputPins;
@property (readwrite, copy) NSString *name;


@end
