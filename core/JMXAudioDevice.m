//
//  JMXAudioDevice.m
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

#import "JMXAudioDevice.h"

@interface JMXAudioDevice (Private)
- (void)dispatchIOProcsWithTimeStamp:(const AudioTimeStamp *)inNow
                           inputData:(const AudioBufferList *)inInputData
                           inputTime:(const AudioTimeStamp *)inInputTime
                          outputData:(AudioBufferList *)outOutputData
                          outputTime:(const AudioTimeStamp *)inOutputTime;
@end

static id JMXAudioHardwareDelegate;

static OSStatus demuxIOProc (
                             AudioDeviceID           inDevice,
                             const AudioTimeStamp*   inNow,
                             const AudioBufferList*  inInputData,
                             const AudioTimeStamp*   inInputTime,
                             AudioBufferList*        outOutputData, 
                             const AudioTimeStamp*   inOutputTime,
                             void*                   inClientData
                             )
{
	JMXAudioDevice *device = (JMXAudioDevice *)inClientData;
    [device dispatchIOProcsWithTimeStamp:inNow inputData:inInputData inputTime:inInputTime outputData:outOutputData outputTime:inOutputTime];  
    return noErr;
}

static OSStatus JMXAudioHardwarePropertyListener (
                                                      AudioObjectID inObjectID,
                                                      UInt32 inNumberAddresses,
                                                      const AudioObjectPropertyAddress inAddresses[],
                                                      void * inClientData
                                                 )
{
	NSAutoreleasePool * pool;
	SEL delegateSelector;
	NSString * notificationName = nil;
    int i;
    
    for (i = 0; i < inNumberAddresses; i++) {
        switch(inAddresses[i].mSelector)
        {
            case kAudioHardwarePropertyDevices:
                delegateSelector = @selector(audioHardwareDeviceListDidChange);
                notificationName = kJMXAudioHardwareDeviceListDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultInputDevice:
                delegateSelector = @selector(audioHardwareDefaultInputDeviceDidChange);
                notificationName = kJMXAudioHardwareDefaultInputDeviceDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultOutputDevice:
                delegateSelector = @selector(audioHardwareDefaultOutputDeviceDidChange);
                notificationName = kJMXAudioHardwareDefaultOutputDeviceDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultSystemOutputDevice:
                delegateSelector = @selector(audioHardwareDefaultSystemOutputDeviceDidChange);
                notificationName = kJMXAudioHardwareDefaultSystemOutputDeviceDidChangeNotification;
                break;
                
            default:
                return 0; // unknown notification, do nothing
        }
        
        pool = [[NSAutoreleasePool alloc] init];
        
        if ( JMXAudioHardwareDelegate )
        {
            if ([JMXAudioHardwareDelegate respondsToSelector:delegateSelector])
                [JMXAudioHardwareDelegate performSelector:delegateSelector];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        
        [pool release];
    }
	return 0;
}

static OSStatus JMXAudioDevicePropertyListener (
                                                    
                                                    AudioDeviceID inDevice,
                                                    //AudioObjectID inObjectID,
                                                    UInt32 inNumberAddresses,
                                                    const AudioObjectPropertyAddress inAddresses[],
                                                    void * inClientData
                                                   )
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
    int i;
    for (i = 0; i < inNumberAddresses; i++) {
        NSMutableDictionary * notificationUserInfo = [NSMutableDictionary dictionaryWithCapacity:4];
        
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inDevice] forKey:kJMXAudioDeviceIDKey];
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mElement] forKey:kJMXAudioChannelKey]; // XXX
        [notificationUserInfo setObject:[NSNumber numberWithBool:inAddresses[i].mScope ==  kAudioDevicePropertyScopeInput ? YES : NO] forKey:kJMXAudioDirectionKey];
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mSelector] forKey:kJMXAudioPropertyIDKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kJMXAudioDeviceNotification object:nil userInfo:notificationUserInfo];
    }
    
	[pool release];
	
	return 0;
}

static NSString * _DataSourceNameForID ( AudioDeviceID theDeviceID, JMXAudioDeviceDirection theDirection, UInt32 theChannel, UInt32 theDataSourceID )
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueTranslation theTranslation;
	CFStringRef theCFString;
	NSString * rv;
	
	theTranslation.mInputData = &theDataSourceID;
	theTranslation.mInputDataSize = sizeof(UInt32);
	theTranslation.mOutputData = &theCFString;
	theTranslation.mOutputDataSize = sizeof ( CFStringRef );
	theSize = sizeof(AudioValueTranslation);
    struct AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSourceNameForIDCFString;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    theStatus = AudioObjectGetPropertyData(theDeviceID, &propertyAddress, 0, NULL, &theSize, &theTranslation);
	if (( theStatus == 0 ) && theCFString )
	{
		rv = [NSString stringWithString:(NSString *)theCFString];
		CFRelease ( theCFString );
		return rv;
	}
    
	return nil;
}

static NSString * _ClockSourceNameForID ( AudioDeviceID theDeviceID, JMXAudioDeviceDirection theDirection, UInt32 theChannel, UInt32 theClockSourceID )
{
	OSStatus theStatus;
	NSString * rv;
    CFStringRef theCFString;
    UInt32 theSize;
    
    AudioValueTranslation theTranslation;
	theTranslation.mInputData = &theClockSourceID;
	theTranslation.mInputDataSize = sizeof(UInt32);
	theTranslation.mOutputData = &theCFString;
	theTranslation.mOutputDataSize = sizeof ( CFStringRef );
    theSize = sizeof(AudioValueTranslation);
    struct AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSourceNameForIDCFString;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    theStatus = AudioObjectGetPropertyData( theDeviceID, &propertyAddress, 0, NULL, &theSize, &theTranslation );
	if (( theStatus == 0 ) && theCFString )
	{
		rv = [NSString stringWithString:(NSString *)theCFString];
		CFRelease ( theCFString );
		return rv;
	}
    
	return nil;
}

@implementation JMXAudioDevice

// startup stuff
+ (void) initialize
{
	static Boolean initted = NO;
	
	if(!initted)
	{
		initted = YES;
		JMXAudioHardwareDelegate = nil;
        struct AudioObjectPropertyAddress propertyAddress;
        propertyAddress.mSelector = kAudioObjectPropertySelectorWildcard;
        propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
        propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
        OSStatus theStatus = AudioObjectAddPropertyListener(kAudioObjectSystemObject, 
                                                            &propertyAddress, 
                                                            JMXAudioHardwarePropertyListener, 
                                                            NULL);
        if (theStatus != 0) {
            // TODO - error messages
        }
	}
}

+ (NSArray *)allDevices
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray * theArray;
	UInt32 theSize;
	OSStatus theStatus;
	int numDevices;
	int x;
	AudioDeviceID * deviceList;
	JMXAudioDevice * tmpDevice;
	
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize );
    
	if (theStatus != 0)
		return nil;
	numDevices = theSize / sizeof(AudioDeviceID);
	deviceList = (AudioDeviceID *) malloc ( theSize );
	if (deviceList == NULL) {
		NSLog(@"Can't obtain device list size");
        return nil;
    }
    theStatus = AudioObjectGetPropertyData( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize, deviceList );
    
	if (theStatus != 0)
	{
        NSLog(@"Can't obtain device list");
		free(deviceList);
		return nil;
	}
	
	theArray = [[NSMutableArray alloc] initWithCapacity:numDevices];
	for ( x = 0; x < numDevices; x++ )
	{
		tmpDevice = [[[self class] alloc] initWithDeviceID:deviceList[x]];
		[theArray addObject:tmpDevice];
		[tmpDevice release];
	}
	free(deviceList);
	
	[theArray sortUsingSelector:@selector(_compare:)];
	
	[pool release];
    
	[theArray autorelease];
	return theArray;
}


+ (NSArray *)inputDevices
{
    NSEnumerator * deviceEnumerator = [[self allDevices] objectEnumerator];
	NSMutableArray * rv = [NSMutableArray array];
	JMXAudioDevice * aDevice;
	
	while ( aDevice = [deviceEnumerator nextObject] )
		if ( [aDevice channelsForDirection:kJMXAudioInput] > 0 )
            [rv addObject:aDevice];
    return rv;
}

+ (NSArray *)outputDevices
{
    NSEnumerator * deviceEnumerator = [[self allDevices] objectEnumerator];
	NSMutableArray * rv = [NSMutableArray array];
	JMXAudioDevice * aDevice;
	
	while ( aDevice = [deviceEnumerator nextObject] )
		if ( [aDevice channelsForDirection:kJMXAudioOutput] > 0 )
            [rv addObject:aDevice];
    return rv;
}

+ (NSArray *)devicesWithName:(NSString *)theName havingStreamsForDirection:(JMXAudioDeviceDirection)theDirection
{
	NSEnumerator * deviceEnumerator = [[self allDevices] objectEnumerator];
	NSMutableArray * rv = [NSMutableArray array];
	JMXAudioDevice * aDevice;
	
	while ( aDevice = [deviceEnumerator nextObject] ) {
		if ( [theName isEqual:[aDevice deviceName]] && ( [aDevice channelsForDirection:theDirection] > 0 )) {
			[rv addObject:aDevice];
		}
	}
	return rv;
}

+ (JMXAudioDevice *)deviceWithID:(AudioDeviceID)theID
{
	return [[[[self class] alloc] initWithDeviceID:theID] autorelease];
}

+ (JMXAudioDevice *)deviceWithUID:(NSString *)theUID
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueTranslation theTranslation;
	CFStringRef theCFString;
	unichar * theCharacters;
	AudioDeviceID theID;
	JMXAudioDevice * rv = nil;
	
	theCharacters = (unichar *) malloc ( sizeof(unichar) * [theUID length] );
	[theUID getCharacters:theCharacters];
	
	theCFString = CFStringCreateWithCharactersNoCopy ( NULL, theCharacters, [theUID length], kCFAllocatorNull );
	
	theTranslation.mInputData = &theCFString;
	theTranslation.mInputDataSize = sizeof(CFStringRef);
	theTranslation.mOutputData = &theID;
	theTranslation.mOutputDataSize = sizeof(AudioDeviceID);
	theSize = sizeof(AudioValueTranslation);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyDeviceForUID;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    theStatus = AudioObjectGetPropertyDataSize( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize );
    if (theStatus != 0) {
        // TODO - bail out
    }
    theStatus = AudioObjectGetPropertyData( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize, &theTranslation );
	CFRelease ( theCFString );
	free ( theCharacters );
	if (theStatus == 0)
		rv = [[self class] deviceWithID:theID];
	if ( [theUID isEqual:[rv deviceUID]] )
		return rv;
	return nil;
}

+ (JMXAudioDevice *)_defaultDevice:(int)whichDevice
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioDeviceID theID;
	
	theSize = sizeof(AudioDeviceID);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = whichDevice;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    theStatus = AudioObjectGetPropertyDataSize( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize );
    if (theStatus != 0) {
        // TODO - bail out
    }
    theStatus = AudioObjectGetPropertyData( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize, &theID );
	if (theStatus == 0)
		return [[self class] deviceWithID:theID];
    NSLog(@"Can't init defaultDevice %d (%ld)", whichDevice, (long)theStatus);
	return nil;
}

+ (JMXAudioDevice *)defaultInputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultInputDevice];
}

+ (JMXAudioDevice *)defaultOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultOutputDevice];
}

+ (JMXAudioDevice *)defaultSystemOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultSystemOutputDevice];
}

+ (JMXAudioDevice *)aggregateDevice:(NSString *)name
{
    OSStatus osErr = noErr;
    UInt32 outSize = 0;
    Boolean outWritable;
    	
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyPlugInForBundleID;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
    osErr = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &outSize);
    // Start to create a new aggregate by getting the base audio hardware plugin
    //osErr = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyPlugInForBundleID, &outSize, &outWritable);
    if (osErr != noErr)
        return nil;
    
    AudioValueTranslation pluginAVT;
    
    CFStringRef inBundleRef = CFSTR("com.apple.audio.CoreAudio");
    AudioObjectID pluginID = UINT32_MAX;
    
    pluginAVT.mInputData = &inBundleRef;
    pluginAVT.mInputDataSize = sizeof(inBundleRef);
    pluginAVT.mOutputData = &pluginID;
    pluginAVT.mOutputDataSize = sizeof(pluginID);
    osErr = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, sizeof(AudioValueTranslation), &pluginAVT, &outSize, &outWritable);
    //osErr = AudioHardwareGetProperty(kAudioHardwarePropertyPlugInForBundleID, &outSize, &pluginAVT);
    if (osErr != noErr || pluginID == UINT32_MAX)
        return nil;
    
    
    CFMutableDictionaryRef aggDeviceDict = CFDictionaryCreateMutable(NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    
    NSString *newUID = [NSString stringWithFormat:@"org.JMX.aggregatedevice.%ld", random()];
    // add the name of the device to the dictionary
    CFDictionaryAddValue(aggDeviceDict, CFSTR(kAudioAggregateDeviceNameKey), name);
    
    // add our choice of UID for the aggregate device to the dictionary
    CFDictionaryAddValue(aggDeviceDict, CFSTR(kAudioAggregateDeviceUIDKey), newUID);
    
    //-----------------------
    // Create a CFMutableArray for our sub-device list
    //-----------------------
        
    // we need to append the UID for each device to a CFMutableArray, so create one here
    //CFMutableArrayRef subDevicesArray = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
    
    // just the one sub-device in this example, so append the sub-device's UID to the CFArray
    //CFArrayAppendValue(subDevicesArray, deviceUID);
    
    // if you need to add more than one sub-device, then keep calling CFArrayAppendValue here for the other sub-device UIDs
    
    //-----------------------
    // Feed the dictionary to the plugin, to create a blank aggregate device
    //-----------------------
    
    AudioObjectPropertyAddress pluginAOPA;
    pluginAOPA.mSelector = kAudioPlugInCreateAggregateDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    UInt32 outDataSize;
    
    osErr = AudioObjectGetPropertyDataSize(pluginID, &pluginAOPA, 0, NULL, &outDataSize);
    if (osErr != noErr)
        return nil;
    
    AudioDeviceID outAggregateDevice;
    
    osErr = AudioObjectGetPropertyData(pluginID, &pluginAOPA, sizeof(aggDeviceDict), &aggDeviceDict, &outDataSize, &outAggregateDevice);
    if (osErr != noErr)
        return nil;
    
    // pause for a bit to make sure that everything completed correctly
    // this is to work around a bug in the HAL where a new aggregate device seems to disappear briefly after it is created
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    
    //-----------------------
    // Set the sub-device list
    //-----------------------
    
    pluginAOPA.mSelector = kAudioAggregateDevicePropertyFullSubDeviceList;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    outDataSize = sizeof(CFMutableArrayRef);
    //osErr = AudioObjectSetPropertyData(outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &subDevicesArray);
    //if (osErr != noErr)
      //  return nil;
    
    // pause again to give the changes time to take effect
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    
    //-----------------------
    // Set the master device
    //-----------------------
    
    // set the master device manually (this is the device which will act as the master clock for the aggregate device)
    // pass in the UID of the device you want to use
    pluginAOPA.mSelector = kAudioAggregateDevicePropertyMasterSubDevice;
    pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
    pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
    //outDataSize = sizeof(deviceUID);
    //osErr = AudioObjectSetPropertyData(outAggregateDevice, &pluginAOPA, 0, NULL, outDataSize, &deviceUID);
    //if (osErr != noErr)
      //  return nil;
    
    // pause again to give the changes time to take effect
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
    //-----------------------
    // Clean up
    //-----------------------
    
    // release the CF objects we have created - we don't need them any more
    CFRelease(aggDeviceDict);
    //CFRelease(subDevicesArray);
    
    return [[self class] deviceWithID:outAggregateDevice];
}

- (id)init // head off -new and bad usage
{
	[self dealloc];
	return nil;
}

- (void) dealloc
{
	if ( isRegisteredForNotifications )
		[[NSNotificationCenter defaultCenter] removeObserver:self name:kJMXAudioDeviceNotification object:nil];
	[self setDelegate:nil];
	//[self removeIOProc];
    [self removeIOTarget];
    NSRange textRange;
    
    textRange =[[self deviceUID] rangeOfString:@"org.JMX.aggregatedevice"];
    if (textRange.location != NSNotFound) {
        OSStatus osErr = noErr;
        // Start by getting the base audio hardware plugin        
        UInt32 outSize;
        Boolean outWritable;
        
        AudioObjectPropertyAddress propertyAddress;
        propertyAddress.mSelector = kAudioHardwarePropertyPlugInForBundleID;
        propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
        propertyAddress.mElement = kAudioObjectPropertyElementMaster;
        osErr = AudioObjectGetPropertyDataSize(kAudioObjectSystemObject, &propertyAddress, 0, NULL, &outSize);        
        //osErr = AudioHardwareGetPropertyInfo(kAudioHardwarePropertyPlugInForBundleID, &outSize, &outWritable);
        if (osErr != noErr) {
            // TODO - Error Messages
        }
        AudioValueTranslation pluginAVT;
        
        CFStringRef inBundleRef = CFSTR("com.apple.audio.CoreAudio");
        AudioObjectID pluginID = UINT32_MAX;
        
        pluginAVT.mInputData = &inBundleRef;
        pluginAVT.mInputDataSize = sizeof(inBundleRef);
        pluginAVT.mOutputData = &pluginID;
        pluginAVT.mOutputDataSize = sizeof(pluginID);
        
        osErr = AudioObjectGetPropertyData(kAudioObjectSystemObject, &propertyAddress, sizeof(AudioValueTranslation), &pluginAVT, &outSize, &outWritable);
        //osErr = AudioHardwareGetProperty(kAudioHardwarePropertyPlugInForBundleID, &outSize, &pluginAVT);
        if (osErr != noErr && pluginID != UINT32_MAX) {
            // TODO - Error Messages
        }
        
        // Feed the AudioDeviceID to the plugin, to destroy the aggregate device        
        AudioObjectPropertyAddress pluginAOPA;
        pluginAOPA.mSelector = kAudioPlugInDestroyAggregateDevice;
        pluginAOPA.mScope = kAudioObjectPropertyScopeGlobal;
        pluginAOPA.mElement = kAudioObjectPropertyElementMaster;
        UInt32 outDataSize;
        
        osErr = AudioObjectGetPropertyDataSize(pluginID, &pluginAOPA, 0, NULL, &outDataSize);
        if (osErr != noErr) {
            // TODO - Error Messages
        }
        osErr = AudioObjectGetPropertyData(pluginID, &pluginAOPA, 0, NULL, &outDataSize, &deviceID);
        if (osErr != noErr) {
            // TODO - Error MEssages
        }            
    }

	[super dealloc];
}

- (JMXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID
{
	self = [super init];
    if (self) {
        //myStreams[0] = myStreams[1] = nil;
        //streamsDirty[0] = streamsDirty[1] = true;
        deviceID = theID;
        delegate = nil;
        ioProc = NULL;
        demuxIOProcID = NULL;
        muxStarted = NO;
        isRegisteredForNotifications = NO;
    }
	return self;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p id %d> %@", [self className], self, [self deviceID], [self deviceName]];
}

- (NSString *)deviceUID
{
	OSStatus theStatus;
	CFStringRef theCFString;
	NSString * rv;
	UInt32 theSize;
	
	theSize = sizeof ( CFStringRef );
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDeviceUID;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, false, &theSize, &theCFString);

	if ( theStatus != 0 || theCFString == NULL )
		return nil;
	rv = [NSString stringWithString:(NSString *)theCFString];
	CFRelease ( theCFString );
	return rv;
}

- (NSString *)deviceManufacturer
{
	OSStatus theStatus;
	CFStringRef theCFString;
	NSString * rv;
	UInt32 theSize;
	
	theSize = sizeof ( CFStringRef );
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioObjectPropertyManufacturer;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData(deviceID, &propertyAddress, 0, NULL, &theSize, &theCFString);

	if ( theStatus != 0 || theCFString == NULL )
		return nil;
	rv = [NSString stringWithString:(NSString *)theCFString];
	CFRelease ( theCFString);
	return rv;
}

- (NSString *)deviceName
{
	OSStatus theStatus;
	CFStringRef theCFString;
	NSString * rv;
	UInt32 theSize;
	
	theSize = sizeof ( CFStringRef );
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioObjectPropertyName;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theCFString);
	if ( theStatus != 0 || theCFString == NULL )
		return nil;
	rv = [NSString stringWithString:(NSString *)theCFString];
	CFRelease ( theCFString );
	return rv;
}

- (NSComparisonResult)_compare:(JMXAudioDevice *)other
{
	NSString * myName, *myUID;
	NSComparisonResult rv;
	
	myName = [self deviceName];
	if ( myName == nil )
		return NSOrderedDescending; // dead devices to the back of the bus!
    
    NSString *otherName = [other deviceName];
    if (!otherName)
        return NSOrderedAscending;

	rv = [myName compare:otherName];
	if ( rv != NSOrderedSame )
		return rv;
	
	myUID = [self deviceUID];
	if ( myUID == nil )
		return NSOrderedDescending;
    
    NSString *otherUID = [other deviceUID];
    if (!otherUID)
        return NSOrderedAscending;
    
	return [myUID compare:otherUID];
}

// real methods
- (NSString *) dataSourceForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theSourceID;

	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSource;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theSourceID );

	if (theStatus == 0)
		return _DataSourceNameForID ( deviceID, theDirection, 0, theSourceID );
	return nil;
}

- (NSArray *) dataSourcesForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	NSMutableArray * rv = [NSMutableArray array];
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSources;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return rv;
    
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return rv;
	}
	for ( x = 0; x < numSources; x++ )
		[rv addObject:_DataSourceNameForID ( deviceID, theDirection, 0, theSourceIDs[x] )];
	free(theSourceIDs);
	return rv;
}

- (Boolean)canSetDataSourceForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize = 0; // XXX
	Boolean rv = NO;
    
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSource;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
    if (theSize)
        rv = YES;
	if ( 0 == theStatus )
		return rv;
	else
	{
		return NO;
	}
}

- (void)setDataSource:(NSString *)theSource forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	
	if ( theSource == nil )
		return;
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSources;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theSourceIDs );

	if (theStatus != 0)
	{
		free(theSourceIDs);
		return;
	}
	
	theSize = sizeof(UInt32);
	for ( x = 0; x < numSources; x++ )
	{
        NSString *newSource = _DataSourceNameForID ( deviceID, theDirection, 0, theSourceIDs[x] );
		if ( newSource && [theSource compare:newSource] == NSOrderedSame )
            AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &theSourceIDs[x] );
	}
	free(theSourceIDs);
}

- (NSString *)clockSourceForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theSourceID;
	
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSource;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theSourceID );
	if (theStatus == 0)
		return _ClockSourceNameForID ( deviceID, theDirection, theChannel, theSourceID );
	return nil;
}

- (NSArray *)clockSourcesForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	NSMutableArray * rv;
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSources;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return nil;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return nil;
	}
	rv = [NSMutableArray arrayWithCapacity:numSources];
	for ( x = 0; x < numSources; x++ )
		[rv addObject:_ClockSourceNameForID ( deviceID, theDirection, theChannel, theSourceIDs[x] )];
	free(theSourceIDs);
	return rv;
}

- (void)setClockSource:(NSString *)theSource forChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	
	if ( theSource == nil )
		return;
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSources;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theSourceIDs );

	if (theStatus != 0) {
		free(theSourceIDs);
		return;
	}
	
	theSize = sizeof(UInt32);
	for ( x = 0; x < numSources; x++ ) {
        NSString *newSource = _ClockSourceNameForID ( deviceID, theDirection, theChannel, theSourceIDs[x] );
		if ( newSource && [theSource compare:newSource] == NSOrderedSame )
            AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &theSourceIDs[x] );
	}
	free(theSourceIDs);
}

- (UInt32)deviceBufferSizeInFrames
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 frameSize;
	
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &frameSize );
	if (theStatus != noErr) {
        // TODO : output an error message
    }
    return frameSize;
}

- (UInt32) deviceMaxVariableBufferSizeInFrames
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 frameSize;
	
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyUsesVariableBufferFrameSizes;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &frameSize );
	if ( noErr == theStatus )
		return frameSize;
	else
		return [self deviceBufferSizeInFrames];
}

- (UInt32) deviceMinBufferSizeInFrames
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueRange theRange;
	
	theSize = sizeof(AudioValueRange);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyBufferFrameSizeRange;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theRange );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
	return (UInt32) theRange.mMinimum;
}

- (UInt32) deviceMaxBufferSizeInFrames
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueRange theRange;
	
	theSize = sizeof(AudioValueRange);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyBufferFrameSizeRange;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theRange );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
    return (UInt32) theRange.mMaximum;
}

- (void) setDeviceBufferSizeInFrames:(UInt32)numFrames
{
	OSStatus theStatus;
	UInt32 theSize;
    
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyBufferFrameSize;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &numFrames );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
}

- (UInt32)deviceLatencyFramesForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 latencyFrames;
	
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyLatency;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &latencyFrames );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
    return latencyFrames;
}

- (UInt32) deviceSafetyOffsetFramesForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 safetyFrames;
	
	theSize = sizeof(UInt32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertySafetyOffset;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &safetyFrames );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
    return safetyFrames;
}

- (NSArray *)channelsByStreamForDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioBufferList * theList;
	NSMutableArray * rv;
	UInt32 x;
	
	rv = [NSMutableArray arrayWithCapacity:1];
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
    propertyAddress.mScope = (theDirection == kJMXAudioInput)
                           ? kAudioDevicePropertyScopeInput
                           : kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return rv;
	theList = (AudioBufferList *) malloc ( theSize );
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theList );
	if (theStatus != 0) {
		free(theList);
		return rv;
	}
	
	for ( x = 0; x < theList->mNumberBuffers; x++ ) {
		[rv addObject:[NSNumber numberWithUnsignedLong:theList->mBuffers[x].mNumberChannels]];
	}
	free(theList);
	return rv;
}

- (UInt32)channelsForDirection:(JMXAudioDeviceDirection)theDirection
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSNumber * theNumberOfChannelsInThisStream;
	NSEnumerator * channelEnumerator;
	UInt32 rv;
	
	rv = 0;
	
	channelEnumerator = [[self channelsByStreamForDirection:theDirection] objectEnumerator];
	while ( theNumberOfChannelsInThisStream = [channelEnumerator nextObject] )
		rv += [theNumberOfChannelsInThisStream unsignedLongValue];
	[pool release];
	return rv;
}


- (JMXAudioFormat *) streamDescriptionForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioStreamBasicDescription theDescription;
	
	theSize = sizeof(AudioStreamBasicDescription);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyStreamFormat;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theDescription );
	if (theStatus == 0)
	{
		return [JMXAudioFormat formatWithAudioStreamDescription:theDescription];
	}
	return nil;
}

// NSArray of MTCoreAudioStreamDescriptions
- (NSArray *) streamDescriptionsForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 numItems;
	UInt32 x;
	AudioStreamBasicDescription * descriptionArray;
	NSMutableArray * rv;
	
	rv = [NSMutableArray arrayWithCapacity:1];
	
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyStreamFormats;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return rv;
	
	descriptionArray = (AudioStreamBasicDescription *) malloc ( theSize );
	numItems = theSize / sizeof(AudioStreamBasicDescription);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, descriptionArray );
	if (theStatus != 0)
	{
		free(descriptionArray);
		return rv;
	}
	
	for ( x = 0; x < numItems; x++ )
		[rv addObject:[JMXAudioFormat formatWithAudioStreamDescription:descriptionArray[x]]];
    
	free(descriptionArray);
	return rv;
}

- (Boolean) setStreamDescription:(JMXAudioFormat *)theDescription forChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioStreamBasicDescription theASBasicDescription;
	
	theASBasicDescription = [theDescription audioStreamBasicDescription];
	theSize = sizeof(AudioStreamBasicDescription);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyStreamFormat;
    propertyAddress.mScope = (theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &theASBasicDescription );
	return (theStatus == 0);
}

- (NSArray *) relatedDevices
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 numDevices;
	AudioDeviceID * deviceList = NULL;
	JMXAudioDevice * tmpDevice;
	NSMutableArray * rv = [NSMutableArray arrayWithObject:self];
	UInt32 x;
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioObjectPropertyOwnedObjects;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    AudioClassID deviceClass = kAudioDeviceClassID;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, sizeof(deviceClass), &deviceClass, &theSize );
    if (theStatus != 0)
		goto finish;
	deviceList = (AudioDeviceID *) malloc ( theSize );
	numDevices = theSize / sizeof(AudioDeviceID);
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, sizeof(deviceClass), &deviceClass, &theSize, deviceList );
	if (theStatus != 0)
	{
		goto finish;
	}
    
	for ( x = 0; x < numDevices; x++ )
	{
		tmpDevice = [[self class] deviceWithID:deviceList[x]];
		if ( ! [self isEqual:tmpDevice] )
		{
			[rv addObject:tmpDevice];
		}
	}
    
finish:
	
	if ( deviceList )
		free(deviceList);
	
	[rv sortUsingSelector:@selector(_compare:)];
	
	return rv;
}

+ (void) setDelegate:(id)theDelegate
{
	JMXAudioHardwareDelegate = theDelegate;
}

+ (id) delegate
{
	return JMXAudioHardwareDelegate;
}

+ (void) attachNotificationsToThisThread
{
	CFRunLoopRef theRunLoop = CFRunLoopGetCurrent();
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyRunLoop;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    AudioObjectSetPropertyData(kAudioObjectSystemObject, 
                               &propertyAddress, 
                               0, 
                               NULL, 
                               sizeof(CFRunLoopRef), 
                               &theRunLoop);
}

- (void) _dispatchDeviceNotification:(NSNotification *)theNotification
{
	NSDictionary * theUserInfo = [theNotification userInfo];
	AudioDeviceID theDeviceID;
	JMXAudioDeviceDirection theDirection;
	UInt32 theChannel;
	AudioDevicePropertyID thePropertyID;
	BOOL hasVolumeInfoDidChangeMethod = false;
	
	theDeviceID = [[theUserInfo objectForKey:kJMXAudioDeviceIDKey] unsignedIntValue];
    
	// if (delegate && (theDeviceID == deviceID))
	if (theDeviceID == deviceID)
	{
		theDirection = ( [[theUserInfo objectForKey:kJMXAudioDirectionKey] boolValue] ) ? kJMXAudioInput : kJMXAudioOutput ;
		theChannel = [[theUserInfo objectForKey:kJMXAudioChannelKey] unsignedIntValue];
		thePropertyID = [[theUserInfo objectForKey:kJMXAudioPropertyIDKey] unsignedIntValue];
        
		switch (thePropertyID)
		{
			case kAudioDevicePropertyVolumeScalar:
			case kAudioDevicePropertyVolumeDecibels:
			case kAudioDevicePropertyMute:
			case kAudioDevicePropertyPlayThru:
				if ([delegate respondsToSelector:@selector(audioDeviceVolumeInfoDidChange:forChannel:forDirection:)])
					hasVolumeInfoDidChangeMethod = true;
				else
					hasVolumeInfoDidChangeMethod = false;
                break;
		}

		switch (thePropertyID)
		{
			case kAudioDevicePropertyDeviceIsAlive:
				if ([delegate respondsToSelector:@selector(audioDeviceDidDie:)])
					[delegate audioDeviceDidDie:self];
				break;
			case kAudioDeviceProcessorOverload:
				if ([delegate respondsToSelector:@selector(audioDeviceDidOverload:)])
					[delegate audioDeviceDidOverload:self];
				break;
			case kAudioDevicePropertyBufferFrameSize:
			case kAudioDevicePropertyUsesVariableBufferFrameSizes:
				if ([delegate respondsToSelector:@selector(audioDeviceBufferSizeInFramesDidChange:)])
					[delegate audioDeviceBufferSizeInFramesDidChange:self];
				break;
			case kAudioDevicePropertyStreams:
				/*
                if (theDirection == kJMXAudioInput)
					streamsDirty[0] = true;
				else
					streamsDirty[1] = true;
				if ([delegate respondsToSelector:@selector(audioDeviceStreamsListDidChange:)])
					[delegate audioDeviceStreamsListDidChange:self];
                */
				break;
			case kAudioDevicePropertyStreamConfiguration:
                /*
				if ([delegate respondsToSelector:@selector(audioDeviceChannelsByStreamDidChange:forDirection:)])
					[delegate performSelector:@selector(audioDeviceChannelsByStreamDidChange:forDirection:) withObject:self withObject:theDirection];
				*/
                break;
			case kAudioDevicePropertyStreamFormat:
				/*
                if ([delegate respondsToSelector:@selector(audioDeviceStreamDescriptionDidChange:forChannel:forDirection:)])
					[delegate audioDeviceStreamDescriptionDidChange:self forChannel:theChannel forDirection:theDirection];
				*/
                break;
			case kAudioDevicePropertyNominalSampleRate:
				if (0 == theChannel && [delegate respondsToSelector:@selector(audioDeviceNominalSampleRateDidChange:)])
					[delegate audioDeviceNominalSampleRateDidChange:self];
				break;
			case kAudioDevicePropertyAvailableNominalSampleRates:
				if (0 == theChannel && [delegate respondsToSelector:@selector(audioDeviceNominalSampleRatesDidChange:)])
					[delegate audioDeviceNominalSampleRatesDidChange:self];
				break;
			case kAudioDevicePropertyVolumeScalar:
                // case kAudioDevicePropertyVolumeDecibels:
				if ([delegate respondsToSelector:@selector(audioDeviceVolumeDidChange:forChannel:forDirection:)])
					[delegate audioDeviceVolumeDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyMute:
				if ([delegate respondsToSelector:@selector(audioDeviceMuteDidChange:forChannel:forDirection:)])
					[delegate audioDeviceMuteDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyPlayThru:
				if ([delegate respondsToSelector:@selector(audioDevicePlayThruDidChange:forChannel:forDirection:)])
					[delegate audioDevicePlayThruDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyDataSource:
				if (theChannel != 0)
					NSLog ( @"JMXAudioDevice kAudioDevicePropertyDataSource theChannel != 0" );
				if ([delegate respondsToSelector:@selector(audioDeviceSourceDidChange:forDirection:)])
					[delegate audioDeviceSourceDidChange:self forDirection:theDirection];
				break;
			case kAudioDevicePropertyClockSource:
				if ([delegate respondsToSelector:@selector(audioDeviceClockSourceDidChange:forChannel:forDirection:)])
					[delegate audioDeviceClockSourceDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyDeviceHasChanged:
				if ([delegate respondsToSelector:@selector(audioDeviceSomethingDidChange:)])
					[delegate audioDeviceSomethingDidChange:self];
				break;
		}
		
	}
}

- (void) _registerForNotifications
{
	if ( ! isRegisteredForNotifications )
	{
        struct AudioObjectPropertyAddress propertyAddress;
        propertyAddress.mSelector = kAudioObjectPropertySelectorWildcard;
        propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
        propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
        OSStatus theStatus = AudioObjectAddPropertyListener(deviceID, 
                                                            &propertyAddress, 
                                                            JMXAudioDevicePropertyListener, 
                                                            NULL);
        if (theStatus != 0) {
            // TODO - error messages
        }   
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_dispatchDeviceNotification:)
                                                     name:kJMXAudioDeviceNotification
                                                   object:nil];
		isRegisteredForNotifications = YES;
	}
}

- (void)setDelegate:(id)theDelegate
{
	delegate = theDelegate;
	if ( delegate )
		[self _registerForNotifications];
}

- (id) delegate
{
	return delegate;
}

#if 0
- (void) setIOProc:(AudioDeviceIOProc)theIOProc withClientData:(void *)theClientData
{
	[self removeIOProc];
	myIOProc = theIOProc;
	myIOProcClientData = theClientData;
}

- (void) removeIOProc
{
	if (myIOProc || myIOInvocation)
	{
		[self deviceStop];
		myIOProc = NULL;
		[myIOInvocation release];
		myIOInvocation = nil;
		myIOProcClientData = NULL;
	}
}

#endif

- (void) setIOTarget:(id)theTarget withSelector:(SEL)theSelector withClientData:(void *)theClientData
{
	[self removeIOTarget];
    SEL selector = @selector(ioCycleForDevice:timeStamp:inputData:inputTime:outputData:outputTime:clientData:);
	myIOInvocation = [[NSInvocation invocationWithMethodSignature:[self methodSignatureForSelector:selector]] retain];
	[myIOInvocation setTarget:theTarget];
	[myIOInvocation setSelector:theSelector];
	[myIOInvocation setArgument:&self atIndex:2];
	[myIOInvocation setArgument:&theClientData atIndex:8];
    
	myIOProcClientData = theClientData;
}

- (void) removeIOTarget
{
	if (myIOInvocation)
	{
		[self deviceStop];
		[myIOInvocation release];
		myIOInvocation = nil;
		myIOProcClientData = NULL;
    }
}

- (Boolean) deviceStart
{

    if (!muxStarted) {
        OSStatus rv = noErr;

        // these can't be done inside the same lock that's held by the IOProc
        // dispatcher, because this can lead to a deadlock with CoreAudio's CAGuard lock
        rv = AudioDeviceCreateIOProcID( deviceID, demuxIOProc, self, &demuxIOProcID );
        if ( noErr == rv )
        {
            
            rv = AudioDeviceStart ( deviceID, demuxIOProc );
        }
        
        if ( noErr != rv )
        {
            // TODO - Error messages
        } else {
            muxStarted = YES;
        }
    }
	return muxStarted;
}

- (void) deviceStop
{
	if (muxStarted)
	{
        AudioDeviceStop ( deviceID, demuxIOProc );
        OSStatus theStatus = AudioDeviceDestroyIOProcID( deviceID, demuxIOProcID );
        if (theStatus == noErr)
            muxStarted = false;
	}
}

- (void) setDevicePaused:(Boolean)shouldPause
{
	if ( shouldPause )
	{
		// [JMXAudioIOProcMux setPause:shouldPause forDevice:self];
        // XXX - IMPLEMENT
        // TODO - do something
	}
	else
	{
		isPaused = FALSE;
	}
}

- (void)dispatchIOProcsWithTimeStamp:(AudioTimeStamp *)inNow
                           inputData:(AudioBufferList *)inInputData
                           inputTime:(AudioTimeStamp *)inInputTime
                          outputData:(AudioBufferList *)outOutputData
                          outputTime:(AudioTimeStamp *)inOutputTime
{
    static OSSpinLock lock;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    OSSpinLockLock(&lock);
    if ( isPaused )
        return;
#if 0        
    if (myIOProc)
    {
        (void)(*myIOProc)( myDevice, inNow, inInputData, inInputTime, outOutputData, inOutputTime, myIOProcClientData );
    }
    else
#endif
    if (myIOInvocation)
    {
        [myIOInvocation setArgument:&inNow atIndex:3];
        [myIOInvocation setArgument:&inInputData atIndex:4];
        [myIOInvocation setArgument:&inInputTime atIndex:5];
        [myIOInvocation setArgument:&outOutputData atIndex:6];
        [myIOInvocation setArgument:&inOutputTime atIndex:7];
        [myIOInvocation invoke];
    }
    OSSpinLockUnlock(&lock);
    [pool drain];
}

- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeScalar;
	
	theSize = sizeof(Float32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;//(theDirection == kJMXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;//theChannel;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theVolumeScalar );
    if ( theStatus == kAudioHardwareUnknownPropertyError ) {
        NSLog(@"Unknown hardware property");
    }
	if (theStatus == 0) {
		return theVolumeScalar;
	}else
		return 0.0;
}

- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(JMXAudioDeviceDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    
    theSize = sizeof(Float32);
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = (theDirection == kJMXAudioInput)
                           ? kAudioDevicePropertyScopeInput
                           : kAudioDevicePropertyScopeOutput;    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &theVolume );
    if (theStatus != noErr) {
        // TODO - output an error message
    }
}

- (OSStatus) ioCycleForDevice:(JMXAudioDevice *)theDevice timeStamp:(const AudioTimeStamp *)inNow inputData:(const AudioBufferList *)inInputData inputTime:(const AudioTimeStamp *)inInputTime outputData:(AudioBufferList *)outOutputData outputTime:(const AudioTimeStamp *)inOutputTime clientData:(void *)inClientData
{
	return noErr;
}

@synthesize deviceID;

@end
