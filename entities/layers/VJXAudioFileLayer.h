//
//  VJXAudioFileLayer.h
//  VeeJay
//
//  Created by xant on 9/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXThreadedEntity.h"

@class VJXAudioFile;

@interface VJXAudioFileLayer : VJXThreadedEntity {
@private
    VJXAudioFile *audioFile;
    VJXPin *outputPin;
}

@end
