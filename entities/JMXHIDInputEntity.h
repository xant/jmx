//
//  JMXHIDInputEntity.h
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXEntity.h"
#import "JMXHIDDevice.h"

@interface JMXHIDInputEntity : JMXEntity <JMXHIDDeviceDelegate>
{
    JMXHIDDevice *device;
    NSString *deviceID;
    JMXInputPin *deviceSelect;
    JMXOutputPin *outputReport;
}

@property (readonly) JMXHIDDevice *device;
@property (retain) NSString *deviceID; // must trigger device selection

+ (NSArray *)availableDevices;

@end

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXHIDInputEntity);
