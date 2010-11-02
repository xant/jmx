//
//  VJXQtVideoCaptureLayer.h
//  VeeJay
//
//  Created by xant on 9/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//
//  This file is part of VeeJay
//
//  VeeJay is free software: you can redistribute it and/or modify
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
//  along with VeeJay.  If not, see <http://www.gnu.org/licenses/>.
//

#import "VJXVideoEntity.h"

#ifndef __VJXQTVIDEOCAPTURELAYER_H__
#define __VJXQTVIDEOCAPTURELAYER_H__
@class VJXQtVideoGrabber;

@interface VJXQtVideoCaptureLayer : VJXVideoEntity
{
@private
	VJXQtVideoGrabber *grabber;
}
@end

#endif

#ifdef __VJXV8__
VJXV8_DECLARE_ENTITY_CONSTRUCTOR(VJXQtVideoCaptureLayer);
#endif