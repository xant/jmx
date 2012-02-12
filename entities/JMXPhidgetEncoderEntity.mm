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

JMXV8_EXPORT_NODE_CLASS(JMXPhidgetEncoderEntity);

@implementation JMXPhidgetEncoderEntity
static int gotAttach(CPhidgetHandle phid, void *context) {
	[(id)context performSelectorOnMainThread:@selector(phidgetAdded:)
								  withObject:nil
							   waitUntilDone:NO];
	return 0;
}

static int gotDetach(CPhidgetHandle phid, void *context) {
	[(id)context performSelectorOnMainThread:@selector(phidgetRemoved:)
								  withObject:nil
							   waitUntilDone:NO];
	return 0;
}

static int gotError(CPhidgetHandle phid, void *context, int errcode, const char *error) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(id)context performSelectorOnMainThread:@selector(ErrorEvent:)
								  withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:errcode],
                                              [NSString stringWithUTF8String:error], nil]
							   waitUntilDone:NO];
	[pool release];
	return 0;
}

static int gotInputChange(CPhidgetEncoderHandle phid, void *context, int ind, int val) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	[(id)context performSelectorOnMainThread:@selector(InputChange:)
								  withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:ind],
                                                                       [NSNumber numberWithInt:val],
                                                                        nil]
							   waitUntilDone:NO];
	[pool release];
	return 0;
}

static int gotPositionChange(CPhidgetEncoderHandle phid, void *context, int ind, int time, int dir) {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int position;
	CPhidgetEncoder_getPosition(phid, ind, &position);
	[(id)context performSelectorOnMainThread:@selector(PositionChange:)
								  withObject:[NSArray arrayWithObjects:
											  [NSNumber numberWithInt:ind], 
											  [NSNumber numberWithInt:time], 
											  [NSNumber numberWithInt:dir], 
											  [NSNumber numberWithInt:position], 
											  nil]
							   waitUntilDone:NO];
	[pool release];
	return 0;
}

- (id)init
{
    self = [super init];
    if (self) {
    
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
        encoders = [[NSMutableArray alloc] initWithCapacity:3];
    }
    return self;
}

- (void)dealloc
{
    [encoders release];
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
/*	
    switch(devid)
	{
		case PHIDID_ENCODER_1ENCODER_1INPUT:

			break;
		case PHIDID_ENCODER_HS_1ENCODER:

			break;
		case PHIDID_ENCODER_HS_4ENCODER_4INPUT:

			break;
		default:
			break;
	}*/
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
            NSMutableArray *pinArray = [NSMutableArray arrayWithCapacity:3];
            [pinArray addObject:[self registerOutputPin:[NSString stringWithFormat:@"encoder%d_position", i]
                                               withType:kJMXNumberPin]];
            [pinArray addObject:[self registerOutputPin:[NSString stringWithFormat:@"encoder%d_ms", i]
                                               withType:kJMXNumberPin]];
            [pinArray addObject:[self registerOutputPin:[NSString stringWithFormat:@"encoder%d_delta", i]
                                               withType:kJMXNumberPin]];
            [encoders addObject:pinArray];
        }
        /*
        switch(devid)
		{
			case PHIDID_ENCODER_1ENCODER_1INPUT:
                
				[[positionSliders cellWithTag:i] setMaxValue:250];
				[[positionSliders cellWithTag:i] setMinValue:-250];
				[[enabledCheckboxes cellWithTag:i] setEnabled:false];
                 
				break;
			case PHIDID_ENCODER_HS_1ENCODER:
                
				[[positionSliders cellWithTag:i] setMaxValue:50000];
				[[positionSliders cellWithTag:i] setMinValue:-50000];
				[[enabledCheckboxes cellWithTag:i] setEnabled:false];
                
				break;
			case PHIDID_ENCODER_HS_4ENCODER_4INPUT:
                
				[[positionSliders cellWithTag:i] setMaxValue:50000];
				[[positionSliders cellWithTag:i] setMinValue:-50000];
				[[enabledCheckboxes cellWithTag:i] setEnabled:true];
                 
				break;
			default:
				break;
		}*/
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
	/*
	[connectedField setTitleWithMnemonic:@"Nothing"];
	[serialField setTitleWithMnemonic:@""];
	[versionField setTitleWithMnemonic:@""];
	[numInputsField setTitleWithMnemonic:@""];
	[numEncodersField setTitleWithMnemonic:@""];
	
	[encoderBox setHidden:TRUE];
	[inputsBox setHidden:TRUE];
	
	NSRect frame = [mainWindow frame];
	int heightChange = frame.size.height - 192;
	frame.origin.y += heightChange;
	frame.size.height -= heightChange;
	[mainWindow setMinSize:frame.size];
	[mainWindow setFrame:frame display:YES animate:NO];
	
	[self setPicture:0:0];
	*/
	[pool release];
	//[mainWindow display];
}

- (void)InputChange:(NSArray *)inputChangeData
{
    /*
	[[inputs cellWithTag:[[inputChangeData objectAtIndex:0] intValue]] 
	 setState:[[inputChangeData objectAtIndex:1] intValue]];*/
}

/* position change */
- (void)PositionChange:(NSArray *)positionChangeData
{
	int index;
	/*
	[[positions cellWithTag:[[positionChangeData objectAtIndex:0] intValue]] 
	 setIntValue:[[positionChangeData objectAtIndex:3] intValue]];
	[[positionSliders cellWithTag:[[positionChangeData objectAtIndex:0] intValue]] 
	 setIntValue:[[positionChangeData objectAtIndex:3] intValue]];
	[[msTimes cellWithTag:[[positionChangeData objectAtIndex:0] intValue]] 
	 setIntValue:[[positionChangeData objectAtIndex:1] intValue]];
	*/
    NSArray *pinArray = [encoders objectAtIndex:[[positionChangeData objectAtIndex:0] intValue]];
    JMXOutputPin *encoderPin = [pinArray objectAtIndex:0];
    JMXOutputPin *timePin = [pinArray objectAtIndex:1];
    JMXOutputPin *deltaPin = [pinArray objectAtIndex:2];
    
    
    timePin.data = [positionChangeData objectAtIndex:1];
    deltaPin.data = [positionChangeData objectAtIndex:2];
    encoderPin.data = [positionChangeData objectAtIndex:3];
    

	if(!CPhidgetEncoder_getIndexPosition(encoder, [[positionChangeData objectAtIndex:0] intValue], &index))
	{
        /*
		[[indexes cellWithTag:[[positionChangeData objectAtIndex:0] intValue]] 
		 setIntValue:index];*/
	}
}

int errorCounter = 0;
- (void)ErrorEvent:(NSArray *)errorEventData
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
			
			NSAttributedString *string = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@\n",errorString]];
			/*
			[[errorEventLog textStorage] beginEditing];
			[[errorEventLog textStorage] appendAttributedString:string];
			[[errorEventLog textStorage] endEditing];
			
			[errorEventLogCounter setIntValue:errorCounter];
			if(![errorEventLogWindow isVisible])
				[errorEventLogWindow setIsVisible:YES];*/
			break;
	}
}



@end
