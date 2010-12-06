//
//  JMXAudioDevice.h
//  JMX
//
//  Created by xant on 9/17/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  initially based on MTCoreAudio
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
/*!
 @header JMXAudioDevice.h
 */
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

/*!
 @enum JMXAudioDeviceDirection
 kJMXAudioInput, input device.
 kJMXAudioOutput, output device
 */

typedef enum {
    kJMXAudioInput,
    kJMXAudioOutput
} JMXAudioDeviceDirection;

/*!
 @protocol JMXAudioDelegate
 @discussion Any delegate must conform to this protocol.
             All notifications from the device will be propagated to the registerd delegate (if any)
 */
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

/*!
 @class JMXAudioDevice
 @discussion This class allows to access any coreaudio device through an obj-c api
 */
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

/*!
 @method defaultInputDevice
 @return <code>JMXAudioDevice</code> for the default system input device
 */
+ (JMXAudioDevice *)defaultInputDevice;
/*!
 @method defaultOutputDevice
 @return <code>JMXAudioDevice</code> for the default system output device
 */
+ (JMXAudioDevice *)defaultOutputDevice;

/*!
 @method inputDevices
 @return <code>NSArray</code> containing all input devices
 */
+ (NSArray *)inputDevices;
/*!
 @method outputDevices
 @return <code>NSArray</code> containing all output devices
 */
+ (NSArray *)outputDevices;
/*!
 @method allDevices
 @return <code>NSArray</code> containing all devices
 */
+ (NSArray *)allDevices;
/*!
 @method devicesWithName:havingStreamsForDirection:
 @param theName the name of the audio device
 @param theDirection the direction of the device
 
 @return <code>NSArray</code> containing all the devices matching the given name
 */
+ (NSArray *)devicesWithName:(NSString *)theName havingStreamsForDirection:(JMXAudioDeviceDirection)theDirection;

/*!
 @method deviceWithID:
 @param theID the id of the audio device
 
 @return <code>JMXAudioDevice</code> containing all the devices matching the given name
 */
+ (JMXAudioDevice *)deviceWithID:(AudioDeviceID)theID;
/*!
 @method deviceWithUID
 @param theUID the uid of the audio device
 
 @return <code>JMXAudioDevice</code> containing all the devices matching the given name
 */
+ (JMXAudioDevice *)deviceWithUID:(NSString *)theUID;

+ (JMXAudioDevice *)defaultSystemOutputDevice;

+ (JMXAudioDevice *)aggregateDevice:(NSString *)name;

/*!
 @method initWithDeviceID:
 @param theID the id of the audio device
 
 @return <code>JMXAudioDevice</code> containing all the devices matching the given name
 */
- (JMXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID;

/*! 
 @method deviceID
 @return the device id
 */
- (AudioDeviceID)deviceID;
/*! 
 @method deviceName
 @return the device name
 */
- (NSString *)deviceName;
/*!
 @method deviceUID
 @return the device UID
 */
- (NSString *)deviceUID;
/*!
 @method deviceManufacturer
 @return the device manufacturer
 */
- (NSString *)deviceManufacturer;
/*!
 @method relatedDevices
 @return <code>NSArray</code> containing all related devices
 */
- (NSArray *)relatedDevices;
/*!
 @method channelsForDirection:
 @param theDirection the direction (kJMXAudioInput/kJMXAudioOutput)
 @return the number of channels for the given direction
 */
- (UInt32)channelsForDirection:(JMXAudioDeviceDirection)theDirection;
/*!
 @method setDelegate:
 @param theDelegate the delegate to which events must be sent
 */
- (void)setDelegate:(id<JMXAudioDelegate>)theDelegate;

#if 0
- (void) setIOProc:(AudioDeviceIOProc)theIOProc withClientData:(void *)theClientData;
- (void) removeIOProc;
#endif
/*!
 @method setIOTarget:withSelector:withClientData:
 @param theTarget the target to use fo  i/o operations
 @param theSelector message to send to the target
 @param theClientData user-data sent to the target when called
 */
- (void) setIOTarget:(id)theTarget withSelector:(SEL)theSelector withClientData:(void *)theClientData;
/*!
 @method removeIOTarget
 @discussion Remove the actual IO Target
 */
- (void) removeIOTarget;
/*!
 @method deviceStart
 @discussion start processing the AudioDevice
 */
- (Boolean) deviceStart;
/*!
 @method deviceStop
 */
- (void) deviceStop;
/*!
 @method setDevicePaused:
 @param shouldPause boolean flag to indicate whether or not the device is paused
 */
- (void) setDevicePaused:(Boolean)shouldPause;

/*!
 @method volumeForChannel:forDirection:
 @param theChannel the channel
 @param theDirection the direction
 */
- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;
/*!
 @method setVolume:forChannel:forDirection:
 @param theVolume the new volume value
 @param theChannel the channel
 @param theDirection the direction
 */
- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;

/*!
 @method streamDescriptionForChannelforChannel:forDirection:
 @param theChannel the channel
 @param theDirection the direction
 */
- (JMXAudioFormat *) streamDescriptionForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection;

@end
