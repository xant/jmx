//
//  JMXVideoCapture.mm
//  JMX
//
//  Created by xant on 12/21/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "JMXVideoCapture.h"


@implementation JMXVideoCapture

@synthesize device;

+ (NSString *)defaultDevice
{
    return nil;
}

+ (NSArray *)availableDevices
{
    return nil;
}

- (void)start
{
    [self activate];
}

- (void)stop
{
    [self deactivate];
}

@end
