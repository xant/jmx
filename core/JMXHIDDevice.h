//
//  JMXHIDDevice.h
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#ifndef __JMXHIDDEVICE_H__
#define __JMXHIDDEVICE_H__

#import <Foundation/Foundation.h>
#include "HID_Utilities_External.h"

#pragma mark JMXHIDDeviceIdentifier

typedef struct {
    long vendorID;
    long productID;
} JMXHIDDeviceIdentifier;

@class JMXHIDDevice;

typedef enum {
    kJMXHIDDeviceReportTypeUnknown = 0,
    kJMXHIDDeviceReportTypeInput,
    kJMXHIDDeviceReportTypeOutput,
    kJMXHIDDeviceReportTypeCount,
    kJMXHIDDeviceReportTypeFeature
} JMXHIDDeviceReportType;

#pragma mark -
#pragma mark JMXHIDDeviceReport

@interface JMXHIDDeviceReport : NSObject {
@private
    NSData *data;
    JMXHIDDeviceReportType type;
}

@property (readonly) NSData *data;
@property (readonly) JMXHIDDeviceReportType type;

- (id)initWithReport:(uint8_t *)report length:(UInt32)length type:(JMXHIDDeviceReportType)type;

@end

#pragma mark -
#pragma mark JMXHIDDeviceValue

@interface JMXHIDDeviceValue : NSObject {
@private
    NSData *data;
}
- (id)initWithValue:(IOHIDValueRef)value;

@end

#pragma mark -
#pragma mark JMXHIDDeviceDelegate

@protocol JMXHIDDeviceDelegate
@required
- (void)device:(JMXHIDDevice *)aDevice didReceiveReport:(JMXHIDDeviceReport *)aReport;
- (void)device:(JMXHIDDevice *)aDevice didChangeValue:(JMXHIDDeviceValue *)aValue;
- (void)deviceRemoved:(JMXHIDDevice *)aDevice;
@end

#pragma mark -
#pragma mark JMXHIDDevice

@interface JMXHIDDevice : NSObject
{
    IOHIDDeviceRef deviceRef;
    id<JMXHIDDeviceDelegate> delegate;
    BOOL active;
}

@property (readonly) IOHIDDeviceRef deviceRef;
@property (readonly) id<JMXHIDDeviceDelegate> delegate;
@property (readonly) BOOL isActive;

+ (NSArray *)availableDevices;
+ (id)deviceMatching:(JMXHIDDeviceIdentifier)identifier delegate:(id<JMXHIDDeviceDelegate>)delegate;
- (id)initWithDeviceRef:(IOHIDDeviceRef)deviceRef delegate:(id<JMXHIDDeviceDelegate>)delegate;

@end

#endif
