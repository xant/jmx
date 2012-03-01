//
//  JMXPhidgetEncoderEntity.h
//  JMX
//
//  Created by Andrea Guzzo on 2/11/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Phidget21/Phidget21.h>
#import "JMXEntity.h"
#import "JMXV8.h"

@interface JMXPhidgetEncoderEntity : JMXEntity
{
@protected
    CPhidgetEncoderHandle encoder;
    int numInputs, numEncoders;
    NSMutableArray *encoders;
    NSNumber *frequency;
    uint64_t lastPulseTime;
    NSMutableDictionary *accumulators;
    BOOL limitPulse;
}

@property (retain) NSNumber *frequency;
@property (assign) BOOL limitPulse;

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXPhidgetEncoderEntity);

@end
