//
//  MTCoreAudioIOProcMux.h
//  MTCoreAudio
//
//  Created by Michael Thornburgh on Wed Oct 02 2002.
//  Copyright (c) 2002 Michael Thornburgh. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreAudio/CoreAudio.h>


@interface MTCoreAudioIOProcMux : NSObject {
	AudioDeviceID myDeviceID;
	NSMutableSet * deviceProxies;
	NSArray * deviceProxyListCache;
	UInt32 deviceProxyCountCache;
	NSLock * lock;
	NSRecursiveLock * registrationLock;
	AudioBufferList * eachOutputData;
	Boolean isRunning;
#if defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MIN_REQUIRED>=MAC_OS_X_VERSION_10_5)
    AudioDeviceIOProcID demuxIOProcID;
#endif
}

+ (Boolean) registerDevice:(MTCoreAudioDevice *)theDevice;
+ (void) unRegisterDevice:(MTCoreAudioDevice *)theDevice;
+ (void) setPause:(Boolean)shouldPause forDevice:(MTCoreAudioDevice *)theDevice;

@end
