//
//  JMXHIDDevice.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXHIDDevice.h"
#include <CoreFoundation/CoreFoundation.h>
#include <Carbon/Carbon.h>

#include <IOKit/hid/IOHIDLib.h>

#pragma mark -
#pragma mark JMXHIDDeviceValue

@implementation JMXHIDDeviceValue

- (id)initWithValue:(IOHIDValueRef)aValue
{
    self = [super init];
    if (self) {
        data = [[NSData dataWithBytes:IOHIDValueGetBytePtr(aValue)
                               length:IOHIDValueGetLength(aValue)] retain];
    }
    return self;
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}

@end

#pragma mark -
#pragma mark JMXHIDDeviceReport

@implementation JMXHIDDeviceReport

@synthesize data, type;

- (id)initWithReport:(uint8_t *)report length:(UInt32)length type:(JMXHIDDeviceReportType)aType
{
    self = [super init];
    if (self) {
        data = [[NSData dataWithBytes:report
                               length:length] retain];
        type = aType;
    }
    return self;
}

- (void)dealloc
{
    [data release];
    [super dealloc];
}

@end

#pragma mark -
#pragma mark JMXHIDDeviceDevice

@interface JMXHIDDevice ()
- (void) deactivate;
@end

static void JMXIOHIDValueCallback(
                                  void *context, 
                                  IOReturn result, 
                                  void *sender, 
                                  IOHIDValueRef value)
{
    JMXHIDDevice *device = (JMXHIDDevice *)context;
    
    IOHIDElementRef element = IOHIDValueGetElement(value);
    HIDDumpElementInfo(element);
    //    if (IOHIDElementIsRelative(element)) {
    //        
    //    }
    
    JMXHIDDeviceValue *newValue = [[[JMXHIDDeviceValue alloc] initWithValue:value] autorelease];
    
    if (device.delegate)
        [device.delegate device:device didChangeValue:newValue];
    
}

static void JMXIOHIDReportCallback(
                                   void *context, 
                                   IOReturn result, 
                                   void *sender, 
                                   IOHIDReportType type, 
                                   uint32_t reportID, 
                                   uint8_t *report, 
                                   CFIndex reportLength
                                   )
{
    JMXHIDDevice *device = (JMXHIDDevice *)context;
    JMXHIDDeviceReportType reportType = kJMXHIDDeviceReportTypeUnknown;
    
    switch (type) {
        case kIOHIDReportTypeInput:
            reportType = kJMXHIDDeviceReportTypeInput;
            break;
        case kIOHIDReportTypeOutput:
            reportType = kJMXHIDDeviceReportTypeOutput;
            break;
        case kIOHIDReportTypeCount:
            reportType = kJMXHIDDeviceReportTypeCount;
            break;
        case kIOHIDReportTypeFeature:
            reportType = kJMXHIDDeviceReportTypeFeature;
            break;
        default:
            // TODO - log an error
            break;
    }
    JMXHIDDeviceReport *reportBuffer = [[[JMXHIDDeviceReport alloc]
                                         initWithReport:report
                                         length:(uint32_t)reportLength
                                         type:reportType] autorelease];
    
    if (device.delegate)
        [device.delegate device:device didReceiveReport:reportBuffer];
}

static void JMXIOHIDRemoveCallback(void *context, IOReturn result, void *sender)
{
    JMXHIDDevice *device = (JMXHIDDevice *)context;
    
    if (device.delegate)
        [device.delegate deviceRemoved:device];
    
    [device deactivate];
}

@implementation JMXHIDDevice

@synthesize deviceRef, delegate;
@synthesize isActive = active;

+ (void)initialize
{
    HIDBuildDeviceList(0, 0);
}

+ (id)deviceMatching:(JMXHIDDeviceIdentifier)identifier delegate:(id<JMXHIDDeviceDelegate>)delegate
{
    for (NSData *deviceData in [self availableDevices]) {
        //JMXHIDDeviceIdentifier *identifier = (JMXHIDDeviceIdentifier *)malloc(sizeof(JMXHIDDeviceIdentifier));
        IOHIDDeviceRef deviceRef = (IOHIDDeviceRef)(NSData *)[deviceData bytes];
        long vendorID = IOHIDDevice_GetVendorID(deviceRef);
        long productID = IOHIDDevice_GetProductID(deviceRef);
        if (vendorID == identifier.vendorID && productID == identifier.productID)
            return [[[JMXHIDDevice alloc] initWithDeviceRef:deviceRef delegate:delegate] autorelease];
    }
    return nil;
}

+ (NSArray *)availableDevices
{
    NSMutableArray *devices = [NSMutableArray arrayWithCapacity:25];
    
    HIDRebuildDevices();
    if (HIDHaveDeviceList()) {
        UInt32 deviceCount = HIDCountDevices();
        IOHIDDeviceRef deviceRef = HIDGetFirstDevice();
        UInt32 deviceIndex = 0;
        while (deviceIndex < deviceCount - 1) {
            HIDDumpDeviceInfo(deviceRef);
            deviceRef = HIDGetNextDevice(deviceRef);
            deviceIndex++;
            [devices addObject:[NSData dataWithBytesNoCopy:deviceRef length:sizeof(IOHIDDeviceRef) freeWhenDone:NO]];
        }
    }
    return devices;
}

- (id)initWithDeviceRef:(IOHIDDeviceRef)aDeviceRef delegate:(id<JMXHIDDeviceDelegate>)aDelegate
{
    self = [super init];
    if (self) {
        deviceRef = aDeviceRef;
        IOReturn tIOReturn = IOHIDDeviceOpen(deviceRef, kIOHIDOptionsTypeNone);
        //require_noerr(tIOReturn, Oops);
        IOHIDDeviceRegisterInputValueCallback(deviceRef, JMXIOHIDValueCallback, self);
        uint8_t *buffer = malloc(255);
        IOHIDDeviceRegisterInputReportCallback(deviceRef, buffer, 255, JMXIOHIDReportCallback, self);
        IOHIDDeviceRegisterRemovalCallback(deviceRef, JMXIOHIDRemoveCallback, self);

        // TODO - try using the current runloop instead of the main runloop
        IOHIDManagerScheduleWithRunLoop( gIOHIDManagerRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode );
        delegate = aDelegate;
        active = YES;
        BOOL dumpElements = NO;
    Oops:   ;
        //return 0;

    }
    return self;
}

- (void)deactivate
{
    IOHIDDeviceUnscheduleFromRunLoop(deviceRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode);
    IOHIDDeviceClose(deviceRef, kIOHIDOptionsTypeNone);
}

- (void)dealloc
{
    if (active)
        [self deactivate];
    [super dealloc];
}

@end
