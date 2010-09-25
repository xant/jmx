//
//  VJXAudioDevice.m
//  VeeJay
//
//  Created by xant on 9/17/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  based on MTCoreAudio

#import "VJXAudioDevice.h"

@interface VJXAudioDevice (Private)
- (void)dispatchIOProcsWithTimeStamp:(const AudioTimeStamp *)inNow
                           inputData:(const AudioBufferList *)inInputData
                           inputTime:(const AudioTimeStamp *)inInputTime
                          outputData:(AudioBufferList *)outOutputData
                          outputTime:(const AudioTimeStamp *)inOutputTime;
@end

static id VJXAudioHardwareDelegate;

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
	VJXAudioDevice *device = (VJXAudioDevice *)inClientData;
    [device dispatchIOProcsWithTimeStamp:inNow inputData:inInputData inputTime:inInputTime outputData:outOutputData outputTime:inOutputTime];  
    return noErr;
}

static OSStatus VJXAudioHardwarePropertyListener (
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
                notificationName = kVJXAudioHardwareDeviceListDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultInputDevice:
                delegateSelector = @selector(audioHardwareDefaultInputDeviceDidChange);
                notificationName = kVJXAudioHardwareDefaultInputDeviceDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultOutputDevice:
                delegateSelector = @selector(audioHardwareDefaultOutputDeviceDidChange);
                notificationName = kVJXAudioHardwareDefaultOutputDeviceDidChangeNotification;
                break;
            case kAudioHardwarePropertyDefaultSystemOutputDevice:
                delegateSelector = @selector(audioHardwareDefaultSystemOutputDeviceDidChange);
                notificationName = kVJXAudioHardwareDefaultSystemOutputDeviceDidChangeNotification;
                break;
                
            default:
                return 0; // unknown notification, do nothing
        }
        
        pool = [[NSAutoreleasePool alloc] init];
        
        if ( VJXAudioHardwareDelegate )
        {
            if ([VJXAudioHardwareDelegate respondsToSelector:delegateSelector])
                [VJXAudioHardwareDelegate performSelector:delegateSelector];
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
        
        [pool release];
    }
	return 0;
}

static OSStatus VJXAudioDevicePropertyListener (
                                                    
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
        
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inDevice] forKey:kVJXAudioDeviceIDKey];
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mElement] forKey:kVJXAudioChannelKey]; // XXX
        [notificationUserInfo setObject:[NSNumber numberWithBool:inAddresses[i].mScope ==  kAudioDevicePropertyScopeInput ? YES : NO] forKey:kVJXAudioDirectionKey];
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mSelector] forKey:kVJXAudioPropertyIDKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:kVJXAudioDeviceNotification object:nil userInfo:notificationUserInfo];
    }
    
	[pool release];
	
	return 0;
}

@implementation VJXAudioDevice

// startup stuff
+ (void) initialize
{
	static Boolean initted = NO;
	
	if(!initted)
	{
		initted = YES;
		VJXAudioHardwareDelegate = nil;
        struct AudioObjectPropertyAddress propertyAddress;
        propertyAddress.mSelector = kAudioObjectPropertySelectorWildcard;
        propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
        propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
        OSStatus theStatus = AudioObjectAddPropertyListener(kAudioObjectSystemObject, 
                                                            &propertyAddress, 
                                                            VJXAudioHardwarePropertyListener, 
                                                            NULL);
        if (theStatus != 0) {
            // TODO - error messages
        }
	}
}

+ (NSArray *)_devicesForDirection:(VJXAudioDeviceDirection)direction
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray * theArray;
	UInt32 theSize;
	OSStatus theStatus;
	int numDevices;
	int x;
	AudioDeviceID * deviceList;
	VJXAudioDevice * tmpDevice;
	
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioHardwarePropertyDevices;
    propertyAddress.mScope = (direction == kVJXAudioInput)
                           ? kAudioDevicePropertyScopeInput
                           : kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementMaster;
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

+ (NSArray *)allDevices
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSMutableArray *theArray;
    
    NSArray *inputArray = [self _devicesForDirection:kVJXAudioInput];
    NSArray *outputArray = [self _devicesForDirection:kVJXAudioOutput];
    theArray = [NSMutableArray arrayWithArray:inputArray];
    [theArray addObjectsFromArray:outputArray];
	[theArray sortUsingSelector:@selector(_compare:)];
	[pool release];
	//[theArray autorelease];
	return theArray;
}

+ (NSArray *)inputDevices
{
    return [self _devicesForDirection:kVJXAudioInput];
}

+ (NSArray *)outputDevices
{
    return [self _devicesForDirection:kVJXAudioOutput];
}

+ (NSArray *)devicesWithName:(NSString *)theName havingStreamsForDirection:(VJXAudioDeviceDirection)theDirection
{
	NSEnumerator * deviceEnumerator = [[self allDevices] objectEnumerator];
	NSMutableArray * rv = [NSMutableArray array];
	VJXAudioDevice * aDevice;
	
	while ( aDevice = [deviceEnumerator nextObject] )
	{
		if ( [theName isEqual:[aDevice deviceName]] && ( [aDevice channelsForDirection:theDirection] > 0 ))
		{
			[rv addObject:aDevice];
		}
	}
	return rv;
}

+ (VJXAudioDevice *)deviceWithID:(AudioDeviceID)theID
{
	return [[[[self class] alloc] initWithDeviceID:theID] autorelease];
}

+ (VJXAudioDevice *)deviceWithUID:(NSString *)theUID
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueTranslation theTranslation;
	CFStringRef theCFString;
	unichar * theCharacters;
	AudioDeviceID theID;
	VJXAudioDevice * rv = nil;
	
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
    theStatus = AudioObjectGetPropertyData( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize, &theTranslation );
	CFRelease ( theCFString );
	free ( theCharacters );
	if (theStatus == 0)
		rv = [[self class] deviceWithID:theID];
	if ( [theUID isEqual:[rv deviceUID]] )
		return rv;
	return nil;
}

+ (VJXAudioDevice *)_defaultDevice:(int)whichDevice
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
    theStatus = AudioObjectGetPropertyData( kAudioObjectSystemObject, &propertyAddress, 0, NULL, &theSize, &theID );
	if (theStatus == 0)
		return [[self class] deviceWithID:theID];
    NSLog(@"Can't init defaultDevice %d (%d)", whichDevice, theStatus);
	return nil;
}

+ (VJXAudioDevice *)defaultInputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultInputDevice];
}

+ (VJXAudioDevice *)defaultOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultOutputDevice];
}

+ (VJXAudioDevice *)defaultSystemOutputDevice
{
	return [[self class] _defaultDevice:kAudioHardwarePropertyDefaultSystemOutputDevice];
}

- init // head off -new and bad usage
{
	[self dealloc];
	return nil;
}

- (VJXAudioDevice *)initWithDeviceID:(AudioDeviceID)theID
{
	[super init];
	//myStreams[0] = myStreams[1] = nil;
	//streamsDirty[0] = streamsDirty[1] = true;
	deviceID = theID;
	delegate = nil;
	ioProc = NULL;
    demuxIOProcID = NULL;
    muxStarted = NO;
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
	CFRelease ( theCFString );
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

- (NSComparisonResult)_compare:(VJXAudioDevice *)other
{
	NSString * myName, *myUID;
	NSComparisonResult rv;
	
	myName = [self deviceName];
	if ( myName == nil )
		return NSOrderedDescending; // dead devices to the back of the bus!
	rv = [myName compare:[other deviceName]];
	if ( rv != NSOrderedSame )
		return rv;
	
	myUID = [self deviceUID];
	if ( myUID == nil )
		return NSOrderedDescending;
	return [myUID compare:[other deviceUID]];
}

- (NSArray *)channelsByStreamForDirection:(VJXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioBufferList * theList;
	NSMutableArray * rv;
	UInt32 x;
	
	rv = [NSMutableArray arrayWithCapacity:1];
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyStreamConfiguration;
    propertyAddress.mScope = (theDirection == kVJXAudioInput)
                           ? kAudioDevicePropertyScopeInput
                           : kAudioDevicePropertyScopeOutput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( deviceID, &propertyAddress, 0, NULL, &theSize );
	if (theStatus != 0)
		return rv;
	theList = (AudioBufferList *) malloc ( theSize );
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, theList );
	if (theStatus != 0)
	{
		free(theList);
		return rv;
	}
	
	for ( x = 0; x < theList->mNumberBuffers; x++ )
	{
		[rv addObject:[NSNumber numberWithUnsignedLong:theList->mBuffers[x].mNumberChannels]];
	}
	free(theList);
	return rv;
}

- (UInt32)channelsForDirection:(VJXAudioDeviceDirection)theDirection
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



- (NSArray *) relatedDevices
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 numDevices;
	AudioDeviceID * deviceList = NULL;
	VJXAudioDevice * tmpDevice;
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
	VJXAudioHardwareDelegate = theDelegate;
}

+ (id) delegate
{
	return VJXAudioHardwareDelegate;
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
	VJXAudioDeviceDirection theDirection;
	UInt32 theChannel;
	AudioDevicePropertyID thePropertyID;
	BOOL hasVolumeInfoDidChangeMethod = false;
	
	theDeviceID = [[theUserInfo objectForKey:kVJXAudioDeviceIDKey] unsignedLongValue];
    
	// if (delegate && (theDeviceID == deviceID))
	if (theDeviceID == deviceID)
	{
		theDirection = ( [[theUserInfo objectForKey:kVJXAudioDirectionKey] boolValue] ) ? kVJXAudioInput : kVJXAudioOutput ;
		theChannel = [[theUserInfo objectForKey:kVJXAudioChannelKey] unsignedLongValue];
		thePropertyID = [[theUserInfo objectForKey:kVJXAudioPropertyIDKey] unsignedLongValue];
        
		switch (thePropertyID)
		{
			case kAudioDevicePropertyVolumeScalar:
			case kAudioDevicePropertyVolumeDecibels:
			case kAudioDevicePropertyMute:
			case kAudioDevicePropertyPlayThru:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceVolumeInfoDidChange:forChannel:forDirection:)])
					hasVolumeInfoDidChangeMethod = true;
				else
					hasVolumeInfoDidChangeMethod = false;
                break;
		}
		
		switch (thePropertyID)
		{
			case kAudioDevicePropertyDeviceIsAlive:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceDidDie:)])
					[delegate audioDeviceDidDie:self];
				break;
			case kAudioDeviceProcessorOverload:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceDidOverload:)])
					[delegate audioDeviceDidOverload:self];
				break;
			case kAudioDevicePropertyBufferFrameSize:
			case kAudioDevicePropertyUsesVariableBufferFrameSizes:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceBufferSizeInFramesDidChange:)])
					[delegate audioDeviceBufferSizeInFramesDidChange:self];
				break;
			case kAudioDevicePropertyStreams:
				/*
                if (theDirection == kVJXAudioInput)
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
				if (0 == theChannel && [(id)delegate respondsToSelector:@selector(audioDeviceNominalSampleRateDidChange:)])
					[delegate audioDeviceNominalSampleRateDidChange:self];
				break;
			case kAudioDevicePropertyAvailableNominalSampleRates:
				if (0 == theChannel && [(id)delegate respondsToSelector:@selector(audioDeviceNominalSampleRatesDidChange:)])
					[delegate audioDeviceNominalSampleRatesDidChange:self];
				break;
			case kAudioDevicePropertyVolumeScalar:
                // case kAudioDevicePropertyVolumeDecibels:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceVolumeDidChange:forChannel:forDirection:)])
					[delegate audioDeviceVolumeDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyMute:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceMuteDidChange:forChannel:forDirection:)])
					[delegate audioDeviceMuteDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyPlayThru:
				if ([(id)delegate respondsToSelector:@selector(audioDevicePlayThruDidChange:forChannel:forDirection:)])
					[delegate audioDevicePlayThruDidChange:self forChannel:theChannel forDirection:theDirection];
				else if (hasVolumeInfoDidChangeMethod)
					[delegate audioDeviceVolumeInfoDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyDataSource:
				if (theChannel != 0)
					NSLog ( @"VJXAudioDevice kAudioDevicePropertyDataSource theChannel != 0" );
				if ([(id)delegate respondsToSelector:@selector(audioDeviceSourceDidChange:forDirection:)])
					[delegate audioDeviceSourceDidChange:self forDirection:theDirection];
				break;
			case kAudioDevicePropertyClockSource:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceClockSourceDidChange:forChannel:forDirection:)])
					[delegate audioDeviceClockSourceDidChange:self forChannel:theChannel forDirection:theDirection];
				break;
			case kAudioDevicePropertyDeviceHasChanged:
				if ([(id)delegate respondsToSelector:@selector(audioDeviceSomethingDidChange:)])
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
                                                            VJXAudioDevicePropertyListener, 
                                                            NULL);
        if (theStatus != 0) {
            // TODO - error messages
        }   
		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(_dispatchDeviceNotification:)
                                                     name:kVJXAudioDeviceNotification
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
#if defined(MAC_OS_X_VERSION_10_5) && (MAC_OS_X_VERSION_MIN_REQUIRED>=MAC_OS_X_VERSION_10_5)
        rv = AudioDeviceCreateIOProcID( deviceID, demuxIOProc, self, &demuxIOProcID );
#else
        // deprecated in favor of AudioDeviceCreateIOProcID()
        rv = AudioDeviceAddIOProc ( deviceID, demuxIOProc, self );
#endif
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
	if (deviceIOStarted)
	{
		//[VJXAudioIOProcMux unRegisterDevice:self];
		// XXX - IMPLEMENT
        // TODO - unregister ioprocs
        deviceIOStarted = false;
	}
}

- (void) setDevicePaused:(Boolean)shouldPause
{
	if ( shouldPause )
	{
		// [VJXAudioIOProcMux setPause:shouldPause forDevice:self];
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
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    @synchronized(self) {
        if ( isPaused )
            return;
        /*
        if (myIOProc)
        {
            (void)(*myIOProc)( myDevice, inNow, inInputData, inInputTime, outOutputData, inOutputTime, myIOProcClientData );
        }
        else */if (myIOInvocation)
        {
            [myIOInvocation setArgument:&inNow atIndex:3];
            [myIOInvocation setArgument:&inInputData atIndex:4];
            [myIOInvocation setArgument:&inInputTime atIndex:5];
            [myIOInvocation setArgument:&outOutputData atIndex:6];
            [myIOInvocation setArgument:&inOutputTime atIndex:7];
            [myIOInvocation invoke];
        }
    }
    [pool drain];
}

- (Float32)volumeForChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeScalar;
	
	theSize = sizeof(Float32);
#if 1//MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;//(theDirection == kVJXAudioOutput)  ? kAudioDevicePropertyScopeOutput : kAudioDevicePropertyScopeInput;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;//theChannel;
    theStatus = AudioObjectGetPropertyData( deviceID, &propertyAddress, 0, NULL, &theSize, &theVolumeScalar );
#else
	theStatus = AudioDeviceGetProperty ( deviceID, theChannel, theDirection, kAudioDevicePropertyVolumeScalar, &theSize, &theVolumeScalar );
#endif
    if ( theStatus == kAudioHardwareUnknownPropertyError ) {
        NSLog(@"Unknown hardware property");
    }
	if (theStatus == 0) {
        NSLog(@"CIAO");
		return theVolumeScalar;
	}else
		return 0.0;
}

- (void)setVolume:(Float32)theVolume forChannel:(UInt32)theChannel forDirection:(VJXAudioDeviceDirection)theDirection
{
    OSStatus theStatus;
    UInt32 theSize;
    
    theSize = sizeof(Float32);
#if 0//MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = (theDirection == kVJXAudioInput)
                           ? kAudioDevicePropertyScopeInput
                           : kAudioDevicePropertyScopeOutput;    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( deviceID, &propertyAddress, 0, NULL, theSize, &theVolume );
#else
    theStatus = AudioDeviceSetProperty ( deviceID, NULL, theChannel, theDirection, kAudioDevicePropertyVolumeScalar, theSize, &theVolume );
#endif
}

- (OSStatus) ioCycleForDevice:(VJXAudioDevice *)theDevice timeStamp:(const AudioTimeStamp *)inNow inputData:(const AudioBufferList *)inInputData inputTime:(const AudioTimeStamp *)inInputTime outputData:(AudioBufferList *)outOutputData outputTime:(const AudioTimeStamp *)inOutputTime clientData:(void *)inClientData
{
	return noErr;
}

@synthesize deviceID;

@end
