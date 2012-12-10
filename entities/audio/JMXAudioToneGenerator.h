//
//  JMXAudioFrequency.h
//  JMX
//
//  Created by xant on 12/10/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXEntity.h"
#import "JMXRunLoop.h"

@interface JMXAudioToneGenerator : JMXEntity
{
    JMXOutputPin *audioPin;
}

@property (atomic, assign) NSNumber *frequency;
@property (atomic, assign) NSNumber *channelSkew;

@end
