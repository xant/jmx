//
//  JMXHIDInputEntity.m
//  JMX
//
//  Created by Andrea Guzzo on 2/26/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXHIDInputEntity.h"
#import "JMXByteArray.h"
#import "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXHIDInputEntity);

@implementation JMXHIDInputEntity

@synthesize deviceID, device;

+ (NSArray *)availableDevices
{
    NSArray *devicesData = [JMXHIDDevice availableDevices];
    NSMutableArray *devices = [NSMutableArray arrayWithCapacity:devicesData.count];
    for (NSData *deviceData in devicesData) {
        //JMXHIDDeviceIdentifier *identifier = (JMXHIDDeviceIdentifier *)malloc(sizeof(JMXHIDDeviceIdentifier));
        IOHIDDeviceRef deviceRef = (IOHIDDeviceRef)(NSData *)[deviceData bytes];
        //identifier->vendorID = IOHIDDevice_GetVendorID(deviceRef);
        //identifier->productID = IOHIDDevice_GetProductID(deviceRef);
        NSString *deviceString = [NSString stringWithFormat:@"%04x:%04x",
                                  IOHIDDevice_GetVendorID(deviceRef),
                                  IOHIDDevice_GetProductID(deviceRef)];

        [devices addObject:deviceString];/*[NSData dataWithBytesNoCopy:identifier
                                                length:sizeof(JMXHIDDeviceIdentifier)
                                          freeWhenDone:YES]];*/
    }
    return devices;
}

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length()) {
        v8::Handle<Value> arg = (*args)[0];
        v8::String::Utf8Value value(arg);
        if (*value) {
            NSString *deviceName = [NSString stringWithUTF8String:*value];
            self.deviceID = deviceName;
        }
    }   
}

- (NSString *)deviceID
{
    @synchronized(self) {
        return [[deviceID retain] autorelease];
    }
}

- (void)setDeviceID:(NSString *)deviceString
{
    int vendorID, productID;
    if (sscanf([deviceString UTF8String], "%04x:%04x", &productID, &vendorID) == 2) {
        JMXHIDDeviceIdentifier identifier = { productID, vendorID };
        JMXHIDDevice *newDevice = [JMXHIDDevice deviceMatching:identifier delegate:self];
        @synchronized(self) {
            if (newDevice) {
                [device release];
                device = [newDevice retain];
            }
        }
    }
}

- (id)init
{
    self = [super init];
    if (self) {
        NSArray *availableDevices = [[self class] availableDevices];
        deviceSelect = [self registerInputPin:@"deviceID" 
                                     withType:kJMXStringPin 
                                  andSelector:@"setDeviceID:"
                                allowedValues:availableDevices
                                 initialValue:[availableDevices lastObject]];
        outputReport = [self registerOutputPin:@"report"
                                      withType:kJMXByteArrayPin];
    }
    return self;
}

#pragma mark -
#pragma mark JMXHIDDeviceDelegate


- (void)device:(JMXHIDDevice *)aDevice didChangeValue:(JMXHIDDeviceValue *)aValue
{
    
}

- (void)device:(JMXHIDDevice *)aDevice didReceiveReport:(JMXHIDDeviceReport *)aReport
{
    JMXByteArray *byteArray = [JMXByteArray byteArrayWithBytes:(uint8_t *)aReport.data.bytes
                                                        length:aReport.data.length];
    outputReport.data = byteArray;
    
}

- (void)deviceRemoved:(JMXHIDDevice *)aDevice
{
    if (aDevice == device) {
        [device release];
        device = nil;
    }
}

@end
