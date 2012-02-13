//
//  JMXScreenController.h
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class JMXOpenGLView;

@protocol JMXScreenControllerDelegate <NSObject>
- (void)mouseUp:(NSEvent *)event inView:(JMXOpenGLView *)view;
- (void)mouseDown:(NSEvent *)event inView:(JMXOpenGLView *)view;
- (void)mouseMoved:(NSEvent *)event inView:(JMXOpenGLView *)view;
- (void)mouseEntered:(NSEvent *)event inView:(JMXOpenGLView *)view;
- (void)mouseExited:(NSEvent *)event inView:(JMXOpenGLView *)view;
- (void)mouseDragged:(NSEvent *)event inView:(JMXOpenGLView *)view;
@end

@interface JMXScreenController : NSWindowController {
    NSMutableArray *_keyEvents;
    JMXOpenGLView *_view;
    NSTrackingRectTag trackingRect;
    id<JMXScreenControllerDelegate> _delegate;
}

- (id)initWithView:(JMXOpenGLView *)view delegate:(id<JMXScreenControllerDelegate>)delegate;

- (NSDictionary *)getEvent;

@end