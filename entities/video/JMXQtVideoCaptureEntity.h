//
//  JMXQtVideoCaptureLayer.h
//  JMX
//
//  Created by xant on 9/13/10.
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

#import "JMXVideoCapture.h"
#import <AVFoundation/AVFoundation.h>

#ifndef __JMXQTVIDEOCAPTURELAYER_H__
#define __JMXQTVIDEOCAPTURELAYER_H__
@class JMXQtVideoGrabber;

@interface JMXQtVideoCaptureEntity : JMXVideoCapture <AVCaptureVideoDataOutputSampleBufferDelegate>
{
@private
	JMXQtVideoGrabber *grabber;
}
@end

#endif

JMXV8_DECLARE_NODE_CONSTRUCTOR(JMXQtVideoCaptureEntity);
