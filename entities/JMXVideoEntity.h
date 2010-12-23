//
//  JMXVideoEntity.h
//  JMX
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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
#import "JMXEntity.h"

@interface JMXVideoEntity : JMXEntity {
@protected
    NSNumber *saturation;
    NSNumber *brightness;
    NSNumber *contrast;
    NSNumber *alpha;
    NSNumber *rotation;
    NSNumber *scaleRatio;
    NSNumber *fps;
    JMXPoint *origin;
    JMXSize  *size;
    
    CIImage *currentFrame;
    JMXInputPin *fpsPin; // allows to override fps (setting the pin value)
    JMXOutputPin *outputFramePin;
    JMXOutputPin *outputFrameSizePin;

@private
    CIFilter *colorFilter;
    CIFilter *alphaFilter;
}


@property (copy) NSNumber *alpha;
@property (copy) NSNumber *saturation;
@property (copy) NSNumber *brightness;
@property (copy) NSNumber *contrast;
@property (copy) NSNumber *rotation;
@property (copy) NSNumber *scaleRatio;
@property (copy) NSNumber *fps;
@property (copy) JMXPoint *origin;
@property (copy) JMXSize  *size;
@property (readonly) CIImage *currentFrame;

- (void)tick:(uint64_t)timeStamp; // conform to 'tick' required by JMXRunLoop

@end
