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
#import "JMXThreadedEntity.h"

@interface JMXVideoEntity : JMXThreadedEntity {
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
    JMXOutputPin *outputFramePin;
    JMXOutputPin *outputFrameSizePin;

@private
    CIFilter *colorFilter;
    CIFilter *alphaFilter;
}


@property (retain) NSNumber *alpha;
@property (retain) NSNumber *saturation;
@property (retain) NSNumber *brightness;
@property (retain) NSNumber *contrast;
@property (retain) NSNumber *rotation;
@property (retain) NSNumber *scaleRatio;
@property (retain) NSNumber *fps;
@property (retain) JMXPoint *origin;
@property (retain) JMXSize  *size;
@property (readonly) CIImage *currentFrame;

@end
