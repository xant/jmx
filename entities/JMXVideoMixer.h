//
//  JMXVideoMixer.h
//  JMX
//
//  Created by xant on 9/2/10.
//  Copyright 2010 Dyne.org. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import "JMXThreadedEntity.h"

#define JMX_MIXER_DEFAULT_VIDEOSIZE_WIDTH 640
#define JMX_MIXER_DEFAULT_VIDEOSIZE_HEIGHT 480
#define JMX_MIXER_DEFAULT_BLEND_FILTER @"CIScreenBlendMode"

@interface JMXVideoMixer : JMXThreadedEntity {
@public
    JMXSize *outputSize;

@protected
    NSArray *videoInputs;
@private
    JMXInputPin *blendFilterPin;
    JMXInputPin *imageInputPin;
    JMXOutputPin *imageOutputPin;
    JMXOutputPin *imageSizeOutputPin;
    CIImage *currentFrame;
    CIFilter *ciBlendFilter;
    NSString *blendFilter;
    uint64_t lastFrameTime;
}

@property (retain) JMXSize *outputSize;
@property (readwrite, copy) NSString *blendFilter;

@end

#ifdef __JMXV8__
JMXV8_DECLARE_ENTITY_CONSTRUCTOR(JMXVideoMixer);
#endif
