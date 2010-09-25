//
//  VJXAudioDevice.h
//  VeeJay
//
//  Created by xant on 9/17/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  based on MTCoreAudio
#import <Cocoa/Cocoa.h>
#import <CoreAudio/CoreAudio.h>

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
	id < VJXAudioDelegate > delegate;
	AudioDeviceIOProc ioProc;
    Boolean isRegisteredForNotifications;
    AudioDeviceIOProcID demuxIOProcID;
    BOOL muxStarted;
    Boolean deviceIOStarted;
	void * myIOProcClientData;
	NSInvocation * myIOInvocation;
	Boolean isPaused;    
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

- (VJXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID;

- (AudioDeviceID)deviceID;
- (NSString *)deviceName;
- (NSString *)deviceUID;
- (NSString *)deviceManufacturer;
- (NSArray *)relatedDevices;
- (UInt32)channelsForDirection:(VJXAudioDeviceDirection)theDirection;

//- (void) setIOProc:(AudioDeviceIOProc)theIOProc withClientData:(void *)theClientData;
- (void) setIOTarget:(id)theTarget withSelector:(SEL)theSelector withClientData:(void *)theClientData;
//- (void) removeIOProc;
- (void) removeIOTarget;
- (Boolean) deviceStart;
- (void) deviceStop;
- (void) setDevicePaused:(Boolean)shouldPause;

- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;
- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection;

@end
