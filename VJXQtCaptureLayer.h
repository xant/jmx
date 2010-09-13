//
//  VJXQtCaptureLayer.h
//  VeeJay
//
//  Created by xant on 9/13/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <QTKit/QTKit.h>
#import "VJXLayer.h"
#import <Cocoa/Cocoa.h>

#ifndef __VJXQTCAPTURELAYER_H__
#define __VJXQTCAPTURELAYER_H__
@class VJXQtGrabber;

@interface VJXQtCaptureLayer : VJXLayer
{
@private
	VJXQtGrabber *grabber;
}
@end

#endif
