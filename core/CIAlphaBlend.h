/*  JMX
 *  (c) Copyright 2009 Andrea Guzzo <xant@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published 
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */
/*!
 @header CIAlphaBlend.h
 @abstract CoreImageFilter to control the alpha component of an image
 */

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

/*!
 @class CIAlphaBlend
 @abstract custom CIFilter to blend two images honoring the alpha
 @discussion it exposes a single custom input attribute : "backgroundImage"
 */
@interface CIAlphaBlend: CIFilter

#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_6
<CIFilterConstructor>
#endif

{
    CIImage   *inputImage;
    CIImage   *inputBackgroundImage;
}

@end