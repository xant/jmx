//
//  JMXScreenController.m
//  JMX
//
//  Created by Andrea Guzzo on 2/13/12.
//  Copyright (c) 2012 Dyne.org. All rights reserved.
//

#import "JMXScreenController.h"
#import "JMXOpenGLScreen.h"

@implementation JMXScreenController

- (id)initWithView:(JMXOpenGLView *)view delegate:(id<JMXScreenControllerDelegate>)delegate
{
    self = [super initWithWindow:[view window]];
    if (self) {
        _keyEvents = [[NSMutableArray arrayWithCapacity:100] retain];
        _view = view;
        self.window.acceptsMouseMovedEvents = NO;
        trackingRect = [_view addTrackingRect:_view.frame owner:self userData:nil assumeInside:YES];
        _delegate = delegate;
    }
    return self;
}

- (NSDictionary *)getEvent
{
    NSDictionary *event = NULL;
    @synchronized(self) {
        if ([_keyEvents count]) {
            event = [_keyEvents objectAtIndex:0];
            [_keyEvents removeObjectAtIndex:0];
        }
    }
    return event;
}


- (void)insertEvent:(NSEvent *)event OfType:(NSString *)type WithState:(NSString *)state
{
    NSDictionary *entry;
    // create the entry
    entry = [[NSDictionary 
              dictionaryWithObjects:
              [NSArray arrayWithObjects:
               event, state, type, nil
               ]
              forKeys:
              [NSArray arrayWithObjects:
               @"event", @"state", @"type", nil
               ]
              ] retain];
    @synchronized(self) {
        [_keyEvents addObject:entry];
    }
}

- (void)keyUp:(NSEvent *)event
{
    //NSLog(@"Keyrelease (%hu, modifier flags: 0x%x) %@\n", [event keyCode], [event modifierFlags], [event charactersIgnoringModifiers]);
    [self insertEvent:[event retain] OfType:@"kbd" WithState:@"released"];
}

// handle keystrokes
- (void)keyDown:(NSEvent *)event
{
    ///NSLog(@"Keypress (%hu, modifier flags: 0x%x) %@\n", [event keyCode], [event modifierFlags], [event charactersIgnoringModifiers]);
    [self insertEvent:event OfType:@"kbd" WithState:@"pressed"]; 
    if ([event keyCode] == 3 && [event modifierFlags]&NSCommandKeyMask) { // %-f to switch fullscreen
        [_view toggleFullScreen:self];
        [self setWindow:[_view window]];
    }
}

- (void)mouseDown:(NSEvent *)event {
    if (_delegate)
        [_delegate mouseDown:event inView:_view];
}

- (void)mouseUp:(NSEvent *)event {
    if (_delegate)
        [_delegate mouseUp:event inView:_view];
}

- (void)mouseMoved:(NSEvent *)event {
    if (_delegate)
        [_delegate mouseMoved:event inView:_view];
}

- (void)mouseDragged:(NSEvent *)event {
    if (_delegate)
        [_delegate mouseDragged:event inView:_view];
}

- (void)mouseEntered:(NSEvent *)event {
    self.window.acceptsMouseMovedEvents = YES;
    if (_delegate)
        [_delegate mouseEntered:event inView:_view];
}

- (void)mouseExited:(NSEvent *)event {
    self.window.acceptsMouseMovedEvents = NO;
    if (_delegate)
        [_delegate mouseExited:event inView:_view];
}

- (void)dealloc
{
    [_view removeTrackingRect:trackingRect];
    [_keyEvents release];
    [super dealloc];
}

/*
 – mouseDown:
 – mouseDragged:
 – mouseUp:
 – mouseMoved:
 
 – rightMouseDown:
 – rightMouseDragged:
 – rightMouseUp:
 – otherMouseDown:
 – otherMouseDragged:
 – otherMouseUp:
 */

@end