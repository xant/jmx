//
//  JMXCanvasStyle.h
//  JMX
//
//  Created by xant on 1/16/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//
/*!
 @header JMXCanvasStyle.h
 @abstract Canvas style
 @discussion TODO: elaborate
 @related JMXCanvasPattern.h JMXCanvasPattern.h JMXCanvasElement.h JMXDrawPath.h
 */
#import <Cocoa/Cocoa.h>

/*!
 @protocol JMXCanvasStyle
 */
@protocol JMXCanvasStyle <NSObject>

/*!
 @method setFromString:
 @abstract set the style from a css string
 @param style css string representing the (canvas) style to use
 */
- setFromString:(NSString *)style;

@end
