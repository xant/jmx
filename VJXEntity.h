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
    uint64_t previousTimeStamp;
    NSNumber *frequency;
    
@private
    NSThread *worker;
    BOOL active;
    int64_t stamps[25 + 1]; // XXX - 25 should be a constant
    int stampCount;
}

#pragma mark Properties
@property (readonly)BOOL active;
@property (retain) NSNumber *frequency;
@property (readonly) NSMutableArray *inputPins;
@property (readonly) NSMutableArray *outputPins;
@property (readwrite, copy) NSString *name;

#pragma mark Pin API
- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType;
- (void)registerInputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector;

- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType;
- (void)registerOutputPin:(NSString *)pinName withType:(VJXPinType)pinType andSelector:(NSString *)selector;

- (void)unregisterInputPin:(NSString *)pinName;
- (void)unregisterOutputPin:(NSString *)pinName;

- (void)unregisterAllPins;

- (VJXPin *)inputPinWithName:(NSString *)pinName;
- (VJXPin *)outputPinWithName:(NSString *)pinName;

- (void)tick:(uint64_t)timeStamp; // should deliver signals to all output pins

#pragma mark Thread API

- (void)start;
- (void)stop;
- (void)run;

@end
