//
//  VJXObject.h
//  VeeJay
//
//  Created by xant on 9/1/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Foobar is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
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

#define kVJXFpsMaxStamps 25

@interface VJXEntity : NSObject <NSCopying> {
@public
    NSString *name;
    BOOL active;
@protected
    NSMutableDictionary *inputPins;
    NSMutableDictionary *outputPins;
@private
}

#pragma mark Properties
@property (readwrite) BOOL active;
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
- (void)disconnectAllPins;

// autoreleased array of strings (pin names)
- (NSArray *)inputPins;
- (NSArray *)outputPins;

- (VJXPin *)inputPinWithName:(NSString *)pinName;
- (VJXPin *)outputPinWithName:(NSString *)pinName;

- (BOOL)attachObject:(id)receiver
        withSelector:(NSString *)selector
        toOutputPin:(NSString *)pinName;

- (void)outputDefaultSignals:(uint64_t)timeStamp;

- (void)activate;
- (void)deactivate;

@end

