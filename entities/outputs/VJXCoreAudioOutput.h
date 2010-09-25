//
//  VJXCoreAudioOutput.h
//  VeeJay
//
//  Created by xant on 9/16/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXAudioOutput.h"
#import "VJXAudioDevice.h"

@interface VJXCoreAudioOutput : VJXAudioOutput {
    VJXAudioDevice *outputDevice;
}

@end
