//
//  JMXPhidgetEncoderEntity.m
//  JMX
//
//  Created by Andrea Guzzo on 2/11/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXPhidgetEncoderEntity.h"
#import "JMXScript.h"
#import "JMXByteArray.h"
#import <QuartzCore/QuartzCore.h>

JMXV8_EXPORT_NODE_CLASS(JMXPhidgetEncoderEntity);

#pragma mark JMXPhidgetEncoderEntityAccumulator
@interface JMXPhidgetEncoderEntityAccumulator : NSObject
{
    int time;
    int delta;
}
@property (nonatomic, assign) int time;
@property (nonatomic, assign) int delta;

- (void)reset;
@end


@implementation JMXPhidgetEncoderEntityAccumulator

@synthesize time, delta;

- (void)reset
{
    self.time = 0;
    self.delta = 0;
}

@end

#pragma mark -
#pragma mark JMXPhidgetEncoderEntity

@interface JMXPhidgetEncoderEntity () // private interface
- (void)inputChange:(NSArray *)inputChangeData;
- (void)positionChange:(NSArray *)positionChangeData;

- (void)phidgetAdded:(id)nothing;
- (void)phidgetRemoved:(id)nothing;
- (void)errorEvent:(NSArray *)errorEventData;
@end

@implementation JMXPhidgetEncoderEntity

@synthesize frequency, lastPulseTime, limitPulse;

static int gotAttach(CPhidgetHandle phid, void *context) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(JMXPhidgetEncoderEntity *)context phidgetAdded:nil];
    [pool release];
	return 0;
}

static int gotDetach(CPhidgetHandle phid, void *context) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(JMXPhidgetEncoderEntity *)context phidgetRemoved:nil];
    [pool release];
	return 0;
}

static int gotError(CPhidgetHandle phid, void *context, int errcode, const char *error) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(JMXPhidgetEncoderEntity *)context errorEvent:[NSArray arrayWithObjects:[NSNumber numberWithInt:errcode],
                                                                             [NSString stringWithUTF8String:error], nil]];
	[pool release];
	return 0;
}

static int gotInputChange(CPhidgetEncoderHandle phid, void *context, int ind, int val) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXPhidgetEncoderEntity *entity = (JMXPhidgetEncoderEntity *)context;

	[entity inputChange:[NSArray arrayWithObjects:[NSNumber numberWithInt:ind],
                                                  [NSNumber numberWithInt:val], nil]];
	[pool release];
	return 0;
}

static int gotPositionChange(CPhidgetEncoderHandle phid, void *context, int ind, int time, int dir) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    JMXPhidgetEncoderEntity *entity = (JMXPhidgetEncoderEntity *)context;
    int position;
    CPhidgetEncoder_getPosition(phid, ind, &position);
    [entity positionChange:[NSArray arrayWithObjects:
                            [NSNumber numberWithInt:ind], 
                            [NSNumber numberWithInt:time], 
                            [NSNumber numberWithInt:dir], 
                            [NSNumber numberWithInt:position], nil]];
	[pool release];
	return 0;
}

- (id)init
{
    self = [super init];
    if (self) {
        encoders = [[NSMutableArray alloc] initWithCapacity:3];
        accumulators = [[NSMutableDictionary alloc] initWithCapacity:5];
        self.frequency = [NSNumber numberWithDouble:30.0];
        CPhidgetEncoder_create(&encoder);
        CPhidget_set_OnAttach_Handler((CPhidgetHandle)encoder, gotAttach, self);
        CPhidget_set_OnDetach_Handler((CPhidgetHandle)encoder, gotDetach, self);
        CPhidget_set_OnError_Handler((CPhidgetHandle)encoder, gotError, self);
        CPhidgetEncoder_set_OnInputChange_Handler(encoder, gotInputChange, self);
        CPhidgetEncoder_set_OnPositionChange_Handler(encoder, gotPositionChange, self);
        int serial = -1, remote = 0;
        /*
         if(remote)
         CPhidget_openRemote((CPhidgetHandle)encoder, serial, NULL, [[passwordField stringValue] UTF8String]);
         else*/
        CPhidget_open((CPhidgetHandle)encoder, serial);
    }
    return self;
}

- (void)dealloc
{
    [encoders release];
    CPhidget_close((CPhidgetHandle)encoder);
    CPhidget_delete((CPhidgetHandle)encoder);
    [frequency release];
    [accumulators release];
    [super dealloc];
}

- (void)phidgetAdded:(id)nothing
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int serial, version, i;
	const char *name;
	CPhidget_DeviceID devid;
	
	CPhidget_getSerialNumber((CPhidgetHandle)encoder, &serial);
	CPhidget_getDeviceVersion((CPhidgetHandle)encoder, &version);
	CPhidget_getDeviceName((CPhidgetHandle)encoder, &name);
	CPhidget_getDeviceID((CPhidgetHandle)encoder, &devid);
	CPhidgetEncoder_getInputCount(encoder, &numInputs);
	CPhidgetEncoder_getEncoderCount(encoder, &numEncoders);

    for (NSArray *pinArray in encoders) {
        for (JMXPin *pin in pinArray) {
            [self unregisterPin:pin];
        }
    }
    [encoders removeAllObjects];
    for(i=0;i<numEncoders;i++)
	{
		int enabled;
		CPhidgetEncoder_getEnabled(encoder, i, &enabled);
        if (enabled) {
            JMXOutputPin *encoderOutput = [self registerOutputPin:[NSString stringWithFormat:@"encoder%d", i]
                                                         withType:kJMXDictionaryPin];
            JMXOutputPin *encoderValue = [self registerOutputPin:[NSString stringWithFormat:@"value%d", i]
                                                        withType:kJMXNumberPin];
            [encoders addObject:[NSArray arrayWithObjects:encoderOutput, encoderValue, nil]];
        }
    }
    if(numInputs)
	{
		/*[inputs renewRows:1 columns:numInputs];
		[inputLabels renewRows:1 columns:numInputs];*/
		for(i=0;i<numInputs;i++)
		{
		/*	[[inputs cellWithTag:i] setEnabled:FALSE];
			[[inputs cellWithTag:i] setState:FALSE];*/
		}
		//[inputsBox setHidden:FALSE];
	}
}

- (void)phidgetRemoved:(id)nothing
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (JMXPin *pin in encoders) {
        [self unregisterPin:pin];
    }
    [encoders removeAllObjects];
	[pool release];
}

- (void)inputChange:(NSArray *)inputChangeData
{
    JMXPhidgetEncoderEntityAccumulator *accumulatorObj = [accumulators objectForKey:[inputChangeData objectAtIndex:0]];

    uint64_t maxDelta = 1e9 / [self.frequency doubleValue];
    
    uint64_t timeStamp = CVGetCurrentHostTime();
    if (!self.limitPulse || (timeStamp - self.lastPulseTime >= maxDelta)) {
        JMXOutputPin *pin = [[encoders objectAtIndex:[[inputChangeData objectAtIndex:0] intValue]] objectAtIndex:1];
    }
    /*
	[[inputs cellWithTag:[[inputChangeData objectAtIndex:0] intValue]] 
	 setState:[[inputChangeData objectAtIndex:1] intValue]];*/
}

/* position change */
- (void)positionChange:(NSArray *)positionChangeData
{
    JMXPhidgetEncoderEntityAccumulator *accumulatorObj = [accumulators objectForKey:[positionChangeData objectAtIndex:0]];

    uint64_t maxDelta = 1e9 / [self.frequency doubleValue];
    
    uint64_t timeStamp = CVGetCurrentHostTime();
    if (!self.limitPulse || (timeStamp - self.lastPulseTime >= maxDelta))
    {
        
        self.lastPulseTime = timeStamp;

        JMXOutputPin *pin = [[encoders objectAtIndex:[[positionChangeData objectAtIndex:0] intValue]] objectAtIndex:0];
        if (accumulatorObj) {
            pin.data = [NSDictionary dictionaryWithObjectsAndKeys:
                        [positionChangeData objectAtIndex:1], @"time",
                        [positionChangeData objectAtIndex:2], @"delta",
                        [positionChangeData objectAtIndex:3], @"position",
                        nil];
        } else {
            int time = [[positionChangeData objectAtIndex:1] intValue] + accumulatorObj.time;
            int delta = [[positionChangeData objectAtIndex:2] intValue] + accumulatorObj.delta;
            int position = [[positionChangeData objectAtIndex:3] intValue];
            pin.data = [NSDictionary dictionaryWithObjectsAndKeys:
                         [NSNumber numberWithInt:time], @"time",
                         [NSNumber numberWithInt:delta], @"delta",
                         [NSNumber numberWithInt:position], @"position",
                         nil];
            [accumulatorObj reset];
        }
        
        int index;
        if(!CPhidgetEncoder_getIndexPosition(encoder, [[positionChangeData objectAtIndex:0] intValue], &index))
        {

        }
    } else {
        if (!accumulatorObj)
            accumulatorObj = [[[JMXPhidgetEncoderEntityAccumulator alloc] init] autorelease];
        accumulatorObj.time += [[positionChangeData objectAtIndex:1] intValue];
        accumulatorObj.delta += [[positionChangeData objectAtIndex:2] intValue];
        [accumulators setObject:accumulatorObj forKey:[positionChangeData objectAtIndex:0]];
    }
}

int errorCounter = 0;
- (void)errorEvent:(NSArray *)errorEventData
{
	int errorCode = [[errorEventData objectAtIndex:0] intValue];
	NSString *errorString = [errorEventData objectAtIndex:1];
	
	switch(errorCode)
	{
		case EEPHIDGET_BADPASSWORD:
			CPhidget_close((CPhidgetHandle)encoder);
			//[NSApp runModalForWindow:passwordPanel];
			break;
		case EEPHIDGET_BADVERSION:
			CPhidget_close((CPhidgetHandle)encoder);
			NSRunAlertPanel(@"Version mismatch", [NSString stringWithFormat:@"%@\nApplication will now close.", errorString], nil, nil, nil);
			[NSApp terminate:self];
			break;
		default:
			errorCounter++;
			NSLog(@"%@ - Error: %@", self, errorString);
			break;
	}
}

#pragma mark v8 Class Template

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("PhidgetEncoder"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    // set instance methods
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    NSDebug(@"JMXPhidgetEncoderEntity objectTemplate created");
    return objectTemplate;
}
 

@end
