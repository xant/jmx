//
//  JMXScreenController.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//
/*!
 @class JMXScreenController
 @abstract Screen Controller (tracks mouse and keyboard events
 */
#import <Cocoa/Cocoa.h>

@class JMXOpenGLView;
@class JMXSize;

/*!
 @protocol JMXScreenControllerDelegate
 @abstract delegate API for screen controllers.
*/
@protocol JMXScreenControllerDelegate <NSObject>
/*!
 @method mouseUp:inView:
 */
- (void)mouseUp:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method mouseDown:inView:
 */
- (void)mouseDown:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method mouseMoved:inView:
 */
- (void)mouseMoved:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method mouseEntered:inView:
 */
- (void)mouseEntered:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method mouseExited:inView:
 */
- (void)mouseExited:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method mouseDragged:inView:
 */
- (void)mouseDragged:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method keyUp:inView:
 */
- (void)keyUp:(NSEvent *)event inView:(JMXOpenGLView *)view;
/*!
 @method keyDown:inView:
 */
- (void)keyDown:(NSEvent *)event inView:(JMXOpenGLView *)view;

@end

/*!
 @class JMXScreenController
 */
@interface JMXScreenController : NSWindowController {
    JMXOpenGLView *_view;
    NSTrackingRectTag trackingRect;
    id<JMXScreenControllerDelegate> _delegate;
}

/*!
 @method initWithView:delegate:
 */
- (id)initWithView:(JMXOpenGLView *)view delegate:(id<JMXScreenControllerDelegate>)delegate;

/*!
 @method setSize:
 */
- (void)setSize:(JMXSize *)size;

@end