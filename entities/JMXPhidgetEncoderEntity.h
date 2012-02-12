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
    JMXOutputPin *encoderPin;
}

- (void)InputChange:(NSArray *)inputChangeData;
- (void)PositionChange:(NSArray *)positionChangeData;

- (void)phidgetAdded:(id)nothing;
- (void)phidgetRemoved:(id)nothing;

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXPhidgetEncoderEntity);

@end
