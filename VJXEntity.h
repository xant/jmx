//
//  VJXObject.h
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXPin.h"

/*
@protocol VJXThread
#pragma mark Thread API
// entities should implement this message to trigger 
// delivering of signals to all their custom output pins
- (void)tick:(uint64_t)timeStamp;
- (void)start;
- (void)stop;
- (void)run;
@end
*/

@interface VJXEntity : NSObject <NSCopying> {
@public
    NSString *name;
@protected
    NSMutableDictionary *inputPins;
    NSMutableDictionary *outputPins;
    uint64_t previousTimeStamp;
    NSNumber *frequency;
    BOOL active;
@private
    int64_t stamps[25 + 1]; // XXX - 25 should be a constant
    int stampCount;
}

#pragma mark Properties
@property (readonly)BOOL active;
@property (retain) NSNumber *frequency;
@property (readonly) NSDictionary *inputPins;
@property (readonly) NSDictionary *outputPins;
@property (readwrite, copy) NSString *name;

#pragma mark Pin API
- (VJXPin *)registerInputPin:(NSString *)pinName
                    withType:(VJXPinType)pinType;

- (VJXPin *)registerInputPin:(NSString *)pinName
                    withType:(VJXPinType)pinType
                 andSelector:(NSString *)selector;

- (VJXPin *)registerOutputPin:(NSString *)pinName
                     withType:(VJXPinType)pinType;

- (VJXPin *)registerOutputPin:(NSString *)pinName
                     withType:(VJXPinType)pinType
                  andSelector:(NSString *)selector;

- (void)unregisterInputPin:(NSString *)pinName;
- (void)unregisterOutputPin:(NSString *)pinName;

- (void)unregisterAllPins;

- (VJXPin *)inputPinWithName:(NSString *)pinName;
- (VJXPin *)outputPinWithName:(NSString *)pinName;

- (BOOL)attachObject:(id)receiver
        withSelector:(NSString *)selector
        toOutputPin:(NSString *)pinName;

- (void)outputDefaultSignals:(uint64_t)timeStamp;

@end

