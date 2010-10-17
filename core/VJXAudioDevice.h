//
//  VJXAudioDevice.h
//  VeeJay
//
//  Created by xant on 9/17/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  based on MTCoreAudio
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
#import <CoreAudio/CoreAudio.h>
#import "VJXAudioFormat.h"

#define kVJXAudioHardwareDeviceListDidChangeNotification @"VJXCoreAudioHardwareDeviceListDidChangeNotification"
#define kVJXAudioHardwareDefaultInputDeviceDidChangeNotification @"VJXCoreAudioHardwareDefaultInputDeviceDidChangeNotification"
#define kVJXAudioHardwareDefaultOutputDeviceDidChangeNotification @"VJXCoreAudioHardwareDefaultOutputDeviceDidChangeNotification"
#define kVJXAudioHardwareDefaultSystemOutputDeviceDidChangeNotification @"VJXCoreAudioHardwareDefaultSystemOutputDeviceDidChangeNotification"

#define kVJXAudioDeviceNotification @"_MTCoreAudioDeviceNotification"
#define kVJXAudioDeviceIDKey @"DeviceID"
#define kVJXAudioChannelKey @"Channel"
#define kVJXAudioDirectionKey @"Direction"
#define kVJXAudioPropertyIDKey @"PropertyID"

@class VJXAudioDevice;

typedef enum {
    kVJXAudioInput,
    kVJXAudioOutput
} VJXAudioDeviceDirection;

@protocol VJXAudioDelegate
@optional
- (void)audioDeviceDidDie:(VJXAudioDevice *)device;
- (void)audioDeviceDidOverload:(VJXAudioDevice *)device;
- (void)audioDeviceBufferSizeInFramesDidChange:(VJXAudioDevice *)device;
- (void)audioDeviceNominalSampleRateDidChange:(VJXAudioDevice *)device;
- (void)audioDeviceNominalSampleRatesDidChange:(VJXAudioDevice *)device;
- (void)audioDeviceMuteDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceVolumeDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceVolumeInfoDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDevicePlayThruDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceSourceDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceSourceDidChange:(VJXAudioDevice *)device forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceClockSourceDidChange:(VJXAudioDevice *)device forChannel:(SInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)audioDeviceSomethingDidChange:(VJXAudioDevice *)device;
@end

@interface VJXAudioDevice : NSObject {
	AudioDeviceID deviceID;
	id < VJXAudioDelegate, NSObject > delegate;
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

+ (VJXAudioDevice *)defaultInputDevice;
+ (VJXAudioDevice *)defaultOutputDevice;

+ (NSArray *)inputDevices;
+ (NSArray *)outputDevices;
+ (NSArray *)allDevices;
+ (NSArray *)devicesWithName:(NSString *)theName havingStreamsForDirection:(VJXAudioDeviceDirection)theDirection;

+ (VJXAudioDevice *)deviceWithID:(AudioDeviceID)theID;
+ (VJXAudioDevice *)deviceWithUID:(NSString *)theUID;
+ (VJXAudioDevice *)defaultSystemOutputDevice;

+ (VJXAudioDevice *)aggregateDevice:(NSString *)deviceUID withName:(NSString *)name;

- (VJXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID;

- (AudioDeviceID)deviceID;
- (NSString *)deviceName;
- (NSString *)deviceUID;
- (NSString *)deviceManufacturer;
- (NSArray *)relatedDevices;
- (UInt32)channelsForDirection:(VJXAudioDeviceDirection)theDirection;
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

- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;

- (VJXAudioFormat *) streamDescriptionForChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;

@end
