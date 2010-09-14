//
//  MTCoreAudioStream.m
//  MTCoreAudio
//
//  Created by Michael Thornburgh on Thu Jan 03 2002.
//  Copyright (c) 2001 Michael Thornburgh. All rights reserved.
//

#import "MTCoreAudioTypes.h"
#import "MTCoreAudioStreamDescription.h"
#import "MTCoreAudioDevice.h"
#import "MTCoreAudioStream.h"

static NSString * _MTCoreAudioStreamNotification = @"_MTCoreAudioStreamNotification";
static NSString * _MTCoreAudioStreamIDKey = @"StreamID";
static NSString * _MTCoreAudioChannelKey = @"Channel";
static NSString * _MTCoreAudioPropertyIDKey = @"PropertyID";


static NSString * _DataSourceNameForID ( AudioStreamID theStreamID, UInt32 theDataSourceID )
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
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSourceNameForIDCFString;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( theStreamID, &propertyAddress, 0, NULL, &theSize, &theTranslation);
#else
	theStatus = AudioStreamGetProperty ( theStreamID, 0, kAudioDevicePropertyDataSourceNameForIDCFString, &theSize, &theTranslation );
#endif
	if (( theStatus == 0 ) && theCFString )
	{
		rv = [NSString stringWithString:(NSString *)theCFString];
		CFRelease ( theCFString );
		return rv;
	}

	return nil;
}

static NSString * _ClockSourceNameForID ( AudioStreamID theStreamID, UInt32 theClockSourceID )
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioValueTranslation theTranslation;
	CFStringRef theCFString;
	NSString * rv;
	
	theTranslation.mInputData = &theClockSourceID;
	theTranslation.mInputDataSize = sizeof(UInt32);
	theTranslation.mOutputData = &theCFString;
	theTranslation.mOutputDataSize = sizeof ( CFStringRef );
	theSize = sizeof(AudioValueTranslation);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSourceNameForIDCFString;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( theStreamID, &propertyAddress, 0, NULL, &theSize, &theTranslation);
#else
	theStatus = AudioStreamGetProperty ( theStreamID, 0, kAudioDevicePropertyClockSourceNameForIDCFString, &theSize, &theTranslation );
#endif
	if (( theStatus == 0 ) && theCFString )
	{
		rv = [NSString stringWithString:(NSString *)theCFString];
		CFRelease ( theCFString );
		return rv;
	}

	return nil;
}

static OSStatus _MTCoreAudioStreamPropertyListener (
	AudioStreamID inStream,
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    //AudioObjectID inObjectID,
    UInt32 inNumberAddresses,
    const AudioObjectPropertyAddress inAddresses[],
#else
	UInt32 inChannel,
	AudioDevicePropertyID inPropertyID,
#endif
	void * inClientData
)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    for (int i = 0; i < inNumberAddresses; i++) {
        NSMutableDictionary * notificationUserInfo = [NSMutableDictionary dictionaryWithCapacity:4];
        
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inStream] forKey:_MTCoreAudioStreamIDKey];
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mElement] forKey:_MTCoreAudioChannelKey]; // XXX
        [notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inAddresses[i].mSelector] forKey:_MTCoreAudioPropertyIDKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:_MTCoreAudioStreamNotification object:nil userInfo:notificationUserInfo];
    }
#else
    NSMutableDictionary * notificationUserInfo = [NSMutableDictionary dictionaryWithCapacity:4];
	
	[notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inStream] forKey:_MTCoreAudioStreamIDKey];
	[notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inChannel] forKey:_MTCoreAudioChannelKey];
	[notificationUserInfo setObject:[NSNumber numberWithUnsignedLong:inPropertyID] forKey:_MTCoreAudioPropertyIDKey];
	[[NSNotificationCenter defaultCenter] postNotificationName:_MTCoreAudioStreamNotification object:nil userInfo:notificationUserInfo];
#endif

	[pool release];
	
	return 0;
}



@implementation MTCoreAudioStream

- init
{
	[self dealloc];
	return nil;
}

- (MTCoreAudioStream *) initWithStreamID:(AudioStreamID)theStreamID withOwningDevice:(id)theOwningDevice
{
	[super init];
	
	myDelegate = nil;
	myStream = theStreamID;
	parentAudioDevice = theOwningDevice;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_dispatchStreamNotification:) name:_MTCoreAudioStreamNotification object:nil];
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    struct AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioPropertyWildcardPropertyID;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    OSStatus theStatus = AudioObjectAddPropertyListener(theStreamID, 
                                                        &propertyAddress, 
                                                        _MTCoreAudioStreamPropertyListener, 
                                                        NULL);
    if (theStatus != 0) {
        // TODO - error messages
    }   
#else
	AudioStreamAddPropertyListener ( theStreamID, kAudioPropertyWildcardChannel, kAudioPropertyWildcardPropertyID, _MTCoreAudioStreamPropertyListener, NULL );
#endif

	return self;
}

- (MTCoreAudioDirection) direction
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theDirection;
	
	theSize = sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioStreamPropertyDirection;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theDirection);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioStreamPropertyDirection, &theSize, &theDirection );
#endif
	if (( theStatus == 0 ) && (theDirection == 1 ))
		return kMTCoreAudioDeviceRecordDirection;
	else
		return kMTCoreAudioDevicePlaybackDirection;
}

- (NSString *) streamName
{
	OSStatus theStatus;
	CFStringRef theCFString;
	NSString * rv = nil;
	UInt32 theSize;
	
	theSize = sizeof ( CFStringRef );
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDeviceNameCFString;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theCFString);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyDeviceNameCFString, &theSize, &theCFString );
#endif
	if ( theStatus != 0 )
		return nil;
	if ( theCFString )
	{
		rv = [NSString stringWithString:(NSString *)theCFString];
		CFRelease ( theCFString );
	}
	return rv;
}

- (NSString *) description
{
	return [NSString stringWithFormat:@"<%@: %p %@ id %d> %@", [self className], self, [self direction] == kMTCoreAudioDeviceRecordDirection ? @"Record" : @"Playback", [self streamID], [self streamName]];
}

- (id) owningDevice
{
	return parentAudioDevice;
}

- (AudioStreamID) streamID
{
	return myStream;
}


- (void) _dispatchStreamNotification:(NSNotification *)theNotification
{
	id theDelegate;
	AudioStreamID theStreamID;
	UInt32 theChannel;
	AudioDevicePropertyID thePropertyID;
	NSDictionary * theUserInfo = [theNotification userInfo];
	BOOL hasVolumeInfoDidChangeMethod = false;
	MTCoreAudioStreamSide theSide = kMTCoreAudioStreamLogicalSide;
	
	theStreamID = [[theUserInfo objectForKey:_MTCoreAudioStreamIDKey] unsignedLongValue];
	
	if (myDelegate)
		theDelegate = myDelegate;
	else
		theDelegate = [parentAudioDevice delegate];
	
	if ( theDelegate && ( theStreamID == myStream ))
	{
		theChannel = [[theUserInfo objectForKey:_MTCoreAudioChannelKey] unsignedLongValue];
		thePropertyID = [[theUserInfo objectForKey:_MTCoreAudioPropertyIDKey] unsignedLongValue];
		
		switch (thePropertyID)
		{
			case kAudioDevicePropertyVolumeScalar:
			case kAudioDevicePropertyVolumeDecibels:
			case kAudioDevicePropertyMute:
			case kAudioDevicePropertyPlayThru:
				if ([theDelegate respondsToSelector:@selector(audioStreamVolumeInfoDidChange:forChannel:)])
					hasVolumeInfoDidChangeMethod = true;
				else
					hasVolumeInfoDidChangeMethod = false;
			break;
		}

		switch (thePropertyID)
		{
			case kAudioStreamPropertyPhysicalFormat:
				theSide = kMTCoreAudioStreamPhysicalSide;
			case kAudioDevicePropertyStreamFormat:
				if ([theDelegate respondsToSelector:@selector(audioStreamStreamDescriptionDidChange:forSide:)])
					[theDelegate audioStreamStreamDescriptionDidChange:self forSide:theSide];
				break;
			case kAudioDevicePropertyDataSource:
				if ([theDelegate respondsToSelector:@selector(audioStreamSourceDidChange:)])
					[theDelegate audioStreamSourceDidChange:self];
				break;
			case kAudioDevicePropertyClockSource:
				if ([theDelegate respondsToSelector:@selector(audioStreamClockSourceDidChange:)])
					[theDelegate audioStreamClockSourceDidChange:self];
				break;
			case kAudioDevicePropertyVolumeScalar:
			// case kAudioDevicePropertyVolumeDecibels:
				if ([theDelegate respondsToSelector:@selector(audioStreamVolumeDidChange:forChannel:)])
					[theDelegate audioStreamVolumeDidChange:self forChannel:theChannel];
				else if (hasVolumeInfoDidChangeMethod)
					[theDelegate audioStreamVolumeInfoDidChange:self forChannel:theChannel];
				break;
			case kAudioDevicePropertyMute:
				if ([theDelegate respondsToSelector:@selector(audioStreamMuteDidChange:forChannel:)])
					[theDelegate audioStreamMuteDidChange:self forChannel:theChannel];
				else if (hasVolumeInfoDidChangeMethod)
					[theDelegate audioStreamVolumeInfoDidChange:self forChannel:theChannel];
				break;
			case kAudioDevicePropertyPlayThru:
				if ([theDelegate respondsToSelector:@selector(audioStreamPlayThruDidChange:forChannel:)])
					[theDelegate audioStreamPlayThruDidChange:self forChannel:theChannel];
				else if (hasVolumeInfoDidChangeMethod)
					[theDelegate audioStreamVolumeInfoDidChange:self forChannel:theChannel];
				break;
		}
	}

}

- (id) delegate
{
	return myDelegate;
}

- (void) setDelegate:(id)theDelegate
{
	myDelegate = theDelegate;
}

- (UInt32) deviceStartingChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theChannel;
	
	theSize = sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioStreamPropertyStartingChannel;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theChannel);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioStreamPropertyStartingChannel, &theSize, &theChannel );
#endif
	if ( theStatus == 0 )
		return theChannel;
	else
		return 0;
}

- (UInt32) numberChannels
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int rv;
	MTCoreAudioStreamDescription * myDescription;
	
	myDescription = [self streamDescriptionForSide:kMTCoreAudioStreamLogicalSide];
	rv = [myDescription channelsPerFrame];

	[pool release];

	return rv;
}

- (NSString *) dataSource
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theSourceID;
	
	theSize = sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSource;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theSourceID);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyDataSource, &theSize, &theSourceID );
#endif
	if (theStatus == 0)
		return _DataSourceNameForID ( myStream, theSourceID );
	return nil;
}

// NSArray of NSStrings
- (NSArray *)  dataSources
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	NSMutableArray * rv = [NSMutableArray array];
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSources;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, kAudioDevicePropertyDataSources, &theSize, NULL );
#endif
	if (theStatus != 0)
		return rv;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyDataSources, &theSize, theSourceIDs );
#endif
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return rv;
	}
	for ( x = 0; x < numSources; x++ )
		[rv addObject:_DataSourceNameForID ( myStream, theSourceIDs[x] )];
	free(theSourceIDs);
	return rv;
}

- (Boolean)    canSetDataSource
{
	OSStatus theStatus;
	UInt32 theSize;
	
	theSize = sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSource;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
    Boolean rv;

	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, kAudioDevicePropertyDataSource, &theSize, &rv );
#endif
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    return (theStatus == 0) ? YES : NO;
#else
	if ( 0 == theStatus )
		return rv;
	else
	{
		return NO;
	}
#endif
}

- (void)       setDataSource:(NSString *)theSource
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	
	if ( theSource == nil )
		return;
    
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyDataSources;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, kAudioDevicePropertyDataSources, &theSize, NULL );
#endif
	if (theStatus != 0)
		return;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyDataSources, &theSize, theSourceIDs );
#endif
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return;
	}
	
	theSize = sizeof(UInt32);
	for ( x = 0; x < numSources; x++ )
	{
		if ( [theSource compare:_DataSourceNameForID ( myStream, theSourceIDs[x] )] == NSOrderedSame )
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
            theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theSourceIDs[x] );
#else
			(void) AudioStreamSetProperty ( myStream, NULL, 0, kAudioDevicePropertyDataSource, theSize, &theSourceIDs[x] );
#endif
	}
	free(theSourceIDs);
}

- (NSString *) clockSource
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theSourceID;
	
	theSize = sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSource;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theSourceID);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyClockSource, &theSize, &theSourceID );
#endif
	if (theStatus == 0)
		return _ClockSourceNameForID ( myStream, theSourceID );
	return nil;
}

- (NSArray *)  clockSources
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;
	NSMutableArray * rv;
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSources;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, kAudioDevicePropertyClockSources, &theSize, NULL );
#endif
	if (theStatus != 0)
		return nil;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyClockSources, &theSize, theSourceIDs );
#endif
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return nil;
	}
	rv = [NSMutableArray arrayWithCapacity:numSources];
	for ( x = 0; x < numSources; x++ )
		[rv addObject:_ClockSourceNameForID ( myStream, theSourceIDs[x] )];
	free(theSourceIDs);
	return rv;
}

- (void)       setClockSource:(NSString *)theSource
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 * theSourceIDs;
	UInt32 numSources;
	UInt32 x;

	if ( theSource == nil )
		return;
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyClockSources;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, kAudioDevicePropertyClockSources, &theSize, NULL );
#endif
	if (theStatus != 0)
		return;
	theSourceIDs = (UInt32 *) malloc ( theSize );
	numSources = theSize / sizeof(UInt32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, theSourceIDs );
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, kAudioDevicePropertyClockSources, &theSize, theSourceIDs );
#endif
	if (theStatus != 0)
	{
		free(theSourceIDs);
		return;
	}
	
	theSize = sizeof(UInt32);
	for ( x = 0; x < numSources; x++ )
	{
		if ( [theSource compare:_ClockSourceNameForID ( myStream, theSourceIDs[x] )] == NSOrderedSame )
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
            theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theSourceIDs[x] );
#else
            (void) AudioStreamSetProperty ( myStream, NULL, 0, kAudioDevicePropertyClockSource, theSize, &theSourceIDs[x] );
#endif
	}
	free(theSourceIDs);
}

- (MTCoreAudioStreamDescription *) streamDescriptionForSide:(MTCoreAudioStreamSide)theSide
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioStreamBasicDescription theDescription;
	UInt32 theProperty;
	
	if (theSide == kMTCoreAudioStreamPhysicalSide)
		theProperty = kAudioStreamPropertyPhysicalFormat;
	else
		theProperty = kAudioDevicePropertyStreamFormat;
	
	theSize = sizeof(AudioStreamBasicDescription);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = theProperty;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theDescription);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, theProperty, &theSize, &theDescription );
#endif
	if (theStatus == 0)
	{
		return [[parentAudioDevice streamDescriptionFactory] streamDescriptionWithAudioStreamBasicDescription:theDescription];
	}
	return nil;
}

// NSArray of MTCoreAudioStreamDescriptions
- (NSArray *) streamDescriptionsForSide:(MTCoreAudioStreamSide)theSide
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 numItems;
	UInt32 x;
	AudioStreamBasicDescription * descriptionArray;
	NSMutableArray * rv;
	UInt32 theProperty;
	
	if (theSide == kMTCoreAudioStreamPhysicalSide)
		theProperty = kAudioStreamPropertyPhysicalFormats;
	else
		theProperty = kAudioDevicePropertyStreamFormats;

	rv = [NSMutableArray arrayWithCapacity:1];
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = theProperty;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, 0, NULL, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, 0, theProperty, &theSize, NULL );
#endif
	if (theStatus != 0)
		return rv;
	
	descriptionArray = (AudioStreamBasicDescription *) malloc ( theSize );
	numItems = theSize / sizeof(AudioStreamBasicDescription);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, descriptionArray );
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, theProperty, &theSize, descriptionArray );
#endif
	if (theStatus != 0)
	{
		free(descriptionArray);
		return rv;
	}
	
	for ( x = 0; x < numItems; x++ )
		[rv addObject:[[parentAudioDevice streamDescriptionFactory] streamDescriptionWithAudioStreamBasicDescription:descriptionArray[x]]];

	free(descriptionArray);
	return rv;
}

- (Boolean) setStreamDescription:(MTCoreAudioStreamDescription *)theDescription forSide:(MTCoreAudioStreamSide)theSide
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioStreamBasicDescription theASBasicDescription;
	UInt32 theProperty;
	
	if (theSide == kMTCoreAudioStreamPhysicalSide)
		theProperty = kAudioStreamPropertyPhysicalFormat;
	else
		theProperty = kAudioDevicePropertyStreamFormat;

	
	theASBasicDescription = [theDescription audioStreamBasicDescription];
	theSize = sizeof(AudioStreamBasicDescription);
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = theProperty;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theASBasicDescription);
#else
	theStatus = AudioStreamSetProperty ( myStream, NULL, 0, theProperty, theSize, &theASBasicDescription );
#endif
	if (theStatus != 0)
		printf ("MTCoreAudioStream setStreamDescription:forSide: failed, got %4.4s\n", (char *)&theStatus );
	return (theStatus == 0);
}

- (MTCoreAudioStreamDescription *) matchStreamDescription:(MTCoreAudioStreamDescription *)theDescription forSide:(MTCoreAudioStreamSide)theSide
{
	OSStatus theStatus;
	UInt32 theSize;
	AudioStreamBasicDescription theASBasicDescription;
	UInt32 theMatchProperty;
	
	if (theSide == kMTCoreAudioStreamPhysicalSide)
	{
		theMatchProperty = kAudioStreamPropertyPhysicalFormatMatch;
	}
	else
	{
		theMatchProperty = kAudioDevicePropertyStreamFormatMatch;
	}
		
	theASBasicDescription = [theDescription audioStreamBasicDescription];
	theSize = sizeof(AudioStreamBasicDescription);
    
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = theMatchProperty;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theASBasicDescription);
#else
	theStatus = AudioStreamGetProperty ( myStream, 0, theMatchProperty, &theSize, &theASBasicDescription );
#endif
	if ( theStatus == 0 )
	{
		return [[parentAudioDevice streamDescriptionFactory] streamDescriptionWithAudioStreamBasicDescription:theASBasicDescription];
	}

	return nil;
}

- (MTCoreAudioVolumeInfo) volumeInfoForChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	MTCoreAudioVolumeInfo rv;
	UInt32 theSize;
	UInt32 tmpBool32;
	
	rv.hasVolume = false;
	rv.canMute = false;
	rv.canPlayThru = false;
	rv.theVolume = 0.0;
	rv.isMuted = false;
	rv.playThruIsSet = false;
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = kAudioObjectPropertyElementWildcard;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, sizeof(rv.canSetVolume), &rv.canSetVolume, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, theChannel, kAudioDevicePropertyVolumeScalar, &theSize, &rv.canSetVolume );
#endif
	if (noErr == theStatus)
	{
		rv.hasVolume = true;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, sizeof(rv.canSetVolume), &rv.canSetVolume, &theSize, &rv.theVolume );
#else
		theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyVolumeScalar, &theSize, &rv.theVolume );
#endif
		if (noErr != theStatus)
			rv.theVolume = 0.0;
	}
	
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    propertyAddress.mSelector = kAudioDevicePropertyMute;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, sizeof(rv.canMute), &rv.canMute, &theSize );
#else
	theStatus = AudioStreamGetPropertyInfo ( myStream, theChannel, kAudioDevicePropertyMute, &theSize, &rv.canMute );
#endif
	if (noErr == theStatus)
	{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, sizeof(rv.canMute), &rv.canMute, &theSize, &tmpBool32 );
#else
		theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyMute, &theSize, &tmpBool32 );
#endif
		if (noErr == theStatus)
			rv.isMuted = tmpBool32;
	}
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    propertyAddress.mSelector = kAudioDevicePropertyPlayThru;
    theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, sizeof(rv.canPlayThru), &rv.canPlayThru, &theSize );
#else	
	theStatus = AudioStreamGetPropertyInfo ( myStream, theChannel, kAudioDevicePropertyPlayThru, &theSize, &rv.canPlayThru );
#endif
	if (noErr == theStatus)
	{
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
        propertyAddress.mSelector = kAudioDevicePropertyPlayThru;
        theStatus = AudioObjectGetPropertyDataSize( myStream, &propertyAddress, sizeof(rv.canPlayThru), &rv.canPlayThru, &tmpBool32 );
#else	
		theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyPlayThru, &theSize, &tmpBool32 );
#endif
		if (noErr == theStatus)
			rv.playThruIsSet = tmpBool32;
	}
	
	return rv;
}

- (Float32) volumeForChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeScalar;
	
	theSize = sizeof(Float32);
    
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theVolumeScalar);
#else
	theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyVolumeScalar, &theSize, &theVolumeScalar );
#endif
	if (theStatus == 0)
		return theVolumeScalar;
	else
		return 0.0;
}

- (Float32) volumeInDecibelsForChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeDecibels;
	
	theSize = sizeof(Float32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeDecibels;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, 0, NULL, &theSize, &theVolumeDecibels);
#else
	theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyVolumeDecibels, &theSize, &theVolumeDecibels );
#endif
	if (theStatus == 0)
		return theVolumeDecibels;
	else
		return 0.0;
}

- (void)    setVolume:(Float32)theVolume forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	
	theSize = sizeof(Float32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theVolume);
#else
	theStatus = AudioStreamSetProperty ( myStream, NULL, theChannel, kAudioDevicePropertyVolumeScalar, theSize, &theVolume );
#endif
}

- (void)    setVolumeDecibels:(Float32)theVolumeDecibels forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	
	theSize = sizeof(Float32);
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeDecibels;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theVolumeDecibels);
#else
	theStatus = AudioStreamSetProperty ( myStream, NULL, theChannel, kAudioDevicePropertyVolumeDecibels, theSize, &theVolumeDecibels );
#endif
}

- (Float32) volumeInDecibelsForVolume:(Float32)theVolume forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolumeDecibels;
	
	theSize = sizeof(Float32);
	theVolumeDecibels = theVolume;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeScalarToDecibels;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, sizeof(Float32), &theVolume, &theSize, &theVolumeDecibels);
#else
	theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyVolumeScalarToDecibels, &theSize, &theVolumeDecibels );
#endif
	if (theStatus == 0)
		return theVolumeDecibels;
	else
		return 0.0;
}

- (Float32) volumeForVolumeInDecibels:(Float32)theVolumeDecibels forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	Float32 theVolume;
	
	theSize = sizeof(Float32);
	theVolume = theVolumeDecibels;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyVolumeDecibelsToScalar;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectGetPropertyData( myStream, &propertyAddress, sizeof(Float32), &theVolumeDecibels, &theSize, &theVolume);
#else
	theStatus = AudioStreamGetProperty ( myStream, theChannel, kAudioDevicePropertyVolumeDecibelsToScalar, &theSize, &theVolume );
#endif
	if (theStatus == 0)
		return theVolume;
	else
		return 0.0;
}

- (void)    setMute:(BOOL)isMuted forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 theMuteVal;
	
	theSize = sizeof(UInt32);
	if (isMuted) theMuteVal = 1; else theMuteVal = 0;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyMute;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &theMuteVal);
#else
	theStatus = AudioStreamSetProperty ( myStream, NULL, theChannel, kAudioDevicePropertyMute, theSize, &theMuteVal );
#endif
}

- (void)    setPlayThru:(BOOL)isPlayingThru forChannel:(UInt32)theChannel
{
	OSStatus theStatus;
	UInt32 theSize;
	UInt32 thePlayThruVal;
	
	theSize = sizeof(UInt32);
	if (isPlayingThru) thePlayThruVal = 1; else thePlayThruVal = 0;
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
    AudioObjectPropertyAddress propertyAddress;
    propertyAddress.mSelector = kAudioDevicePropertyPlayThru;
    propertyAddress.mScope = kAudioObjectPropertyScopeWildcard;
    propertyAddress.mElement = theChannel;
    theStatus = AudioObjectSetPropertyData( myStream, &propertyAddress, 0, NULL, theSize, &thePlayThruVal);
#else
	theStatus = AudioStreamSetProperty ( myStream, NULL, theChannel, kAudioDevicePropertyPlayThru, theSize, &thePlayThruVal );
#endif
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:_MTCoreAudioStreamNotification object:nil];
	[super dealloc];
}


@end
