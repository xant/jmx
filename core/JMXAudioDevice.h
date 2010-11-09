//
//  JMXAudioDevice.h
//  JMX
//
//  Created by xant on 9/17/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  based on MTCoreAudio
//
//  This file is part of JMX
//
//  JMX is free software: you can redistribute it and/or modify
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
//  along with JMX.  If not, see <http://www.gnu.org/licenses/>.
//

#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>
#import "JMXAudioFormat.h"

#define kJMXAudioHardwareDeviceListDidChangeNotification @"JMXCoreAudioHardwareDeviceListDidChangeNotification"
#define kJMXAudioHardwareDefaultInputDeviceDidChangeNotification @"JMXCoreAudioHardwareDefaultInputDeviceDidChangeNotification"
#define kJMXAudioHardwareDefaultOutputDeviceDidChangeNotification @"JMXCoreAudioHardwareDefaultOutputDeviceDidChangeNotification"
#define kJMXAudioHardwareDefaultSystemOutputDeviceDidChangeNotification @"JMXCoreAudioHardwareDefaultSystemOutputDeviceDidChangeNotification"

#define kJMXAudioDeviceNotification @"_MTCoreAudioDeviceNotification"
#define kJMXAudioDeviceIDKey @"DeviceID"
#define kJMXAudioChannelKey @"Channel"
#define kJMXAudioDirectionKey @"Direction"
#define kJMXAudioPropertyIDKey @"PropertyID"

@class JMXAudioDevice;

typedef enum {
    kJMXAudioInput,
    kJMXAudioOutput
} JMXAudioDeviceDirection;

@protocol JMXAudioDelegate
@optional
- (void)audioDeviceDidDie:(JMXAudioDevice *)device;
- (void)audioDeviceDidOverload:(JMXAudioDevice *)device;
- (void)audioDeviceBufferSizeInFramesDidChange:(JMXAudioDevice *)device;
- (void)audioDeviceNominalSampleRateDidChange:(JMXAudioDevice *)device;
- (void)audioDeviceNominalSampleRatesDidChange:(JMXAudioDevice *)device;
- (void)audioDeviceMuteDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceVolumeDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceVolumeInfoDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDevicePlayThruDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceSourceDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceSourceDidChange:(JMXAudioDevice *)device forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceClockSourceDidChange:(JMXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)audioDeviceSomethingDidChange:(JMXAudioDevice *)device;
@end

@interface JMXAudioDevice : NSObject {
	AudioDeviceID deviceID;
	id < JMXAudioDelegate, NSObject > delegate;
	AudioDeviceIOProc ioProc;
    Boolean isRegisteredForNotifications;
    AudioDeviceIOProcID demuxIOProcID;
    BOOL muxStarted;
    Boolean deviceIOStarted;
	void * myIOProcClientData;
	NSInvocation * myIOInvocation;
	Boolean isPaused;
    Boolean isAggregate;
}
@property (readonly) AudioDeviceID deviceID;

+ (JMXAudioDevice *)defaultInputDevice;
+ (JMXAudioDevice *)defaultOutputDevice;

+ (NSArray *)inputDevices;
+ (NSArray *)outputDevices;
+ (NSArray *)allDevices;
+ (NSArray *)devicesWithName:(NSString *)theName havingStreamsForDirection:(JMXAudioDeviceDirection)theDirection;

+ (JMXAudioDevice *)deviceWithID:(AudioDeviceID)theID;
+ (JMXAudioDevice *)deviceWithUID:(NSString *)theUID;
+ (JMXAudioDevice *)defaultSystemOutputDevice;

+ (JMXAudioDevice *)aggregateDevice:(NSString *)name;

- (JMXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID;

- (AudioDeviceID)deviceID;
- (NSString *)deviceName;
- (NSString *)deviceUID;
- (NSString *)deviceManufacturer;
- (NSArray *)relatedDevices;
- (UInt32)channelsForDirection:(JMXAudioDeviceDirection)theDirection;
- (void)setDelegate:(id)theDelegate;

#if 0
- (void) setIOProc:(AudioDeviceIOProc)theIOProc withClientData:(void *)theClientData;
- (void) removeIOProc;
#endif
- (void) setIOTarget:(id)theTarget withSelector:(SEL)theSelector withClientData:(void *)theClientData;
- (void) removeIOTarget;
- (Boolean) deviceStart;
- (void) deviceStop;
- (void) setDevicePaused:(Boolean)shouldPause;

- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;

- (JMXAudioFormat *) streamDescriptionForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;

@end
