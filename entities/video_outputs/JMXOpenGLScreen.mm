//
//  JMXOpenGLScreen.m
//  JMX
//
//  Created by xant on 9/2/10.
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

#import <QuartzCore/QuartzCore.h>
#import "JMXContext.h"
#include <QuartzCore/CVDisplayLink.h>
#define __JMXV8__
#include <v8.h>
#include <map>
#import "JMXScript.h"
#import "JMXOpenGLScreen.h"
#import "JMXSize.h"
#import "JMXMouseEvent.h"
#import "JMXKeyboardEvent.h"

#import <AppKit/AppKit.h>
//#import <Carbon/Carbon.h>

JMXV8_EXPORT_NODE_CLASS(JMXOpenGLScreen);

#define kMaxEventsPerSecond 120
static NSString *kEventTypeMouseMove = @"mousemove";
static NSString *kEventTypeMouseDragged = @"mousedragged";

@interface JMXOpenGLViewWrapper : NSObject
{
    JMXOpenGLView *openglView;
}
@property (atomic, assign) JMXOpenGLView *openglView; // weak reference
+ (id)openglViewWrapperWithOpenglView:(JMXOpenGLView *)view;
- (id)initWithOpenglView:(JMXOpenGLView *)view;
@end

@implementation JMXOpenGLViewWrapper
@synthesize openglView;

+ (id)openglViewWrapperWithOpenglView:(JMXOpenGLView *)view
{
    return [[[self alloc] initWithOpenglView:view] autorelease];
}

- (id)initWithOpenglView:(JMXOpenGLView *)view
{
    self = [super init];
    if (self) {
        self.openglView = view;
    }
    return self;
}

- (void)dealloc
{
    /*
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
     */
    [super dealloc];
}

- (NSString *)hashString
{
    return [NSString stringWithFormat:@"%ld", [openglView hash]];
}

@end

static NSMutableDictionary *__openglOutputs = nil;
static CVDisplayLinkRef    displayLink; // the displayLink that runs the show
static CGDirectDisplayID   viewDisplayID;
static CVReturn renderCallback(CVDisplayLinkRef displayLink, 
                               const CVTimeStamp *inNow, 
                               const CVTimeStamp *inOutputTime, 
                               CVOptionFlags flagsIn, 
                               CVOptionFlags *flagsOut, 
                               void *displayLinkContext)
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    for (JMXOpenGLViewWrapper *wrapper in [__openglOutputs allValues]) {
        [wrapper.openglView renderFrame:inNow->hostTime];
    }
    [pool drain];
    return noErr;
}

@implementation JMXOpenGLView

@synthesize currentFrame, frameSize, needsRedraw, invertYCoordinates, backgroundColor;

+ (void)initialize
{
    [super initialize];
    viewDisplayID = CGMainDisplayID();
    //viewDisplayID = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];

    CVReturn ret = CVDisplayLinkCreateWithCGDisplay(viewDisplayID, &displayLink);
    if (ret != noErr) {
        // TODO - Error Messages
    }
    // Set up display link callbacks
    NSLog(@"Creating CVDisplayLink");
    CVDisplayLinkSetOutputCallback(displayLink, renderCallback, nil);
    CVDisplayLinkStart(displayLink);
}

- (id)initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAAccelerated,
        NSOpenGLPFADepthSize, 32,
        0
    };
    NSOpenGLPixelFormat* pixelFormat = [[[NSOpenGLPixelFormat alloc] initWithAttributes:attrs] autorelease];
    return [self initWithFrame:frameRect pixelFormat:pixelFormat];
}

- (id)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    if (self) {
        currentFrame = nil;
        ciContext = nil;
        fullScreen = NO;
        myWindow = nil;
        lastTime = 0;
        [self setSize:frameRect.size];
        lock = [[NSLock alloc] init];
        if (!__openglOutputs) {
            __openglOutputs = [[NSMutableDictionary alloc] initWithCapacity:5];
        }
        JMXOpenGLViewWrapper *wrapper = [JMXOpenGLViewWrapper openglViewWrapperWithOpenglView:self];
        [__openglOutputs setObject:wrapper forKey:[NSNumber numberWithInteger:[self hash]]];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    [self setNeedsDisplay:NO];    
}

- (void)prepareOpenGL
{
    [super prepareOpenGL];
    if (ciContext)
        [ciContext release];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    ciContext = [[CIContext contextWithCGLContext:(CGLContextObj)[[self openGLContext] CGLContextObj]
                                      pixelFormat:(CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj]
                                       colorSpace:colorSpace
                                          options:nil] retain];
    CGColorSpaceRelease(colorSpace);

    [self setNeedsDisplay:YES];
}

- (void)dealloc
{
    [__openglOutputs removeObjectForKey:[NSNumber numberWithInteger:[self hash]]];
    [self cleanup];
    [lock release];
    [super dealloc];
}

- (void)renderFrame:(uint64_t)timeStamp
{
    if (timeStamp-lastTime < 1e9/60) //HC
        return;
    lastTime = timeStamp;
    if (!self.window) {
        return;
    }
    
    if (self.needsRedraw) {
        CIImage *image = [self.currentFrame retain];
        if (image && ciContext) {
            CGRect sourceRect = { { 0, 0, }, { frameSize.width, frameSize.height } };
            CGRect screenFrame = NSRectToCGRect([[self window] contentRectForFrameRect:[self frame]]);
            CGFloat width = screenFrame.size.width;
            CGFloat height = screenFrame.size.height;
            CGFloat scaledWidth = 0;
            CGFloat scaledHeight = 0;
            if (width > height) {
                scaledHeight = height;
                scaledWidth = floor((scaledHeight*frameSize.width)/frameSize.height);
            } else {
                scaledWidth = width;
                scaledHeight = floor((scaledWidth*frameSize.height)/frameSize.width);
            }
            CGRect  destinationRect = CGRectMake(screenFrame.origin.x, screenFrame.origin.y,
                                                 scaledWidth, scaledHeight);
            
            
            if (fullScreen)
            {   
                destinationRect.origin.x = (width-scaledWidth)/2;
                destinationRect.origin.y = (height-scaledHeight)/2;
            }
            if (CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]) != kCGLNoError)
                NSLog(@"Could not lock CGLContext");
            [[self openGLContext] makeCurrentContext];
            glClearColor(0,0,0,0);
            glClear(GL_COLOR_BUFFER_BIT);
            [ciContext drawImage:[image imageByCroppingToRect:sourceRect] inRect:destinationRect fromRect:sourceRect];
            [[self openGLContext] flushBuffer];
            CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
        }
        [image release];
        self.needsRedraw = NO;
    }
    [self setNeedsDisplay:NO];
}

// Called by Cocoa when the view's visible rectangle or bounds change.
- (void)reshape
{
    if (!self.window)
        return;

    if (CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]) != kCGLNoError)
         NSLog(@"Could not lock CGLContext");

    NSRect bounds = [self frame];
    GLfloat minX, minY, maxX, maxY;
    minX = NSMinX(bounds);
    minY = NSMinY(bounds);
    maxX = NSMaxX(bounds);
    maxY = NSMaxY(bounds);
    [[self openGLContext] makeCurrentContext];
    glViewport(0, 0, bounds.size.width, bounds.size.height);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(minX, maxX, minY, maxY, -1.0, 1.0);
    glDisable(GL_DITHER);
    glDisable(GL_ALPHA_TEST);
    glDisable(GL_BLEND);
    glDisable(GL_STENCIL_TEST);
    glDisable(GL_FOG);
    glDisable(GL_DEPTH_TEST);
    glPixelZoom(1.0, 1.0);
    glClearColor(backgroundColor.redComponent, backgroundColor.greenComponent, backgroundColor.blueComponent, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [[self openGLContext] flushBuffer];
    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

- (CIImage *)currentFrame
{
    [lock lock];
    CIImage *image = [currentFrame retain];
    [lock unlock];
    return [image autorelease];
}

- (void)setCurrentFrame:(CIImage *)frame
{
    [lock lock];    
    [currentFrame release];
    currentFrame = [frame retain];
    [lock unlock];
    //[self setNeedsDisplay:YES];
    self.needsRedraw = YES;
    //[self renderFrame:0];
}

- (void)cleanup
{
    if (ciContext) {
        [ciContext release];
        ciContext = nil;
    }
    if (frameSize)
        [frameSize release];
    frameSize = nil;
    self.currentFrame = nil;
}

- (void)setSize:(NSSize)size
{
    NSRect actualRect = [[self window] contentRectForFrameRect:[self frame]];
    // XXX - we actually don't allow setting a 0-size (for neither width nor height)
    if (size.width && size.height &&
        (size.width != actualRect.size.width ||
         size.height != actualRect.size.height))
    {
        if (frameSize)
            [frameSize release];
        frameSize = [[JMXSize sizeWithNSSize:size] retain];
        NSRect newRect = NSMakeRect(actualRect.origin.x, actualRect.origin.y,
                                    frameSize.width, frameSize.height);
        NSRect frameRect;
        NSWindow *window = self.window;
        if (window) {
            frameRect = [window frameRectForContentRect:newRect];
            [window setFrame:frameRect display:NO];
            [self setFrame:frameRect];
            [window setMovable:YES]; // XXX - this shouldn't be necessary
        }
    }
}

- (IBAction)toggleFullScreen:(id)sender
{
    if ([self isInFullScreenMode] || fullScreen) {
        [self exitFullScreenModeWithOptions:nil];
        fullScreen = NO;
    } else {
        //CGDisplayModeRef newMode;
        BOOL exactMatch = NO;
        CGDirectDisplayID currentDisplayID = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];
        //CGDirectDisplayID currentDisplayID = viewDisplayID;
        // Loop through all display modes to determine the closest match.
        // CGDisplayBestModeForParameters is deprecated on 10.6 so we will emulate it's behavior
        // Try to find a mode with the requested depth and equal or greater dimensions first.
        // If no match is found, try to find a mode with greater depth and same or greater dimensions.
        // If still no match is found, just use the current mode.
        CFArrayRef allModes = CGDisplayCopyAllDisplayModes(currentDisplayID, NULL);
        for(int i = 0; i < CFArrayGetCount(allModes); i++)    {
            CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
            CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
            if(CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) != kCFCompareEqualTo)
            {
                CFRelease(pixEnc);
                continue;
            }
            CFRelease(pixEnc);
            if((CGDisplayModeGetWidth(mode) >= frameSize.width) && (CGDisplayModeGetHeight(mode) >= frameSize.height))
            {
                //newMode = mode;
                exactMatch = YES;
                break;
            }
        }
        
        // No depth match was found
        if(!exactMatch)
        {
            for(int i = 0; i < CFArrayGetCount(allModes); i++)
            {
                CGDisplayModeRef mode = (CGDisplayModeRef)CFArrayGetValueAtIndex(allModes, i);
                CFStringRef pixEnc = CGDisplayModeCopyPixelEncoding(mode);
                if(CFStringCompare(pixEnc, CFSTR(IO32BitDirectPixels), kCFCompareCaseInsensitive) != kCFCompareEqualTo)
                {
                    CFRelease(pixEnc);
                    continue;
                }
                CFRelease(pixEnc);
                if((CGDisplayModeGetWidth(mode) >= frameSize.width) && (CGDisplayModeGetHeight(mode) >= frameSize.height))
                {
                    //newMode = mode;
                    break;
                }
            }
        }

        [self enterFullScreenMode:[[self window] screen] 
                      withOptions:[NSDictionary dictionaryWithObjectsAndKeys:
                                   [NSNumber numberWithBool:NO],
                                   NSFullScreenModeAllScreens,
                                   [NSNumber numberWithUnsignedInteger:
                                    NSApplicationPresentationDefault |
                                    NSApplicationPresentationAutoHideMenuBar |
                                    NSApplicationPresentationDisableHideApplication |
                                    NSApplicationPresentationAutoHideDock],
                                   NSFullScreenModeApplicationPresentationOptions,
                                   nil]];
        CFRelease(allModes);
        fullScreen = YES;
    }
    [self reshape];
}
@end

@implementation JMXOpenGLScreen

@synthesize window, view;

- (void)jsInit:(NSValue *)argsValue
{
    [super jsInit:argsValue];
    ctx = [JMXScript getContext];
    self.invertYCoordinates = YES;
}

- (id)initWithSize:(NSSize)screenSize
{
    self = [super initWithSize:screenSize];
    if (self) {
        NSRect frame = NSMakeRect(0, 0, size.width, size.height);
        view = [[JMXOpenGLView alloc] initWithFrame:frame];
        view.backgroundColor = backgroundColor;
        window = [[NSWindow alloc] initWithContentRect:frame                                          
                                             styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask
                                               backing:NSBackingStoreBuffered 
                                                 defer:NO];
        [window setReleasedWhenClosed:NO];
        [window setIsVisible:YES];
        [[window contentView] addSubview:view];
        
        NSRect actualRect = [window contentRectForFrameRect:frame];
        NSRect newRect = NSMakeRect(actualRect.origin.x, actualRect.origin.y,
                                    size.width, size.height);
        
        NSRect frameRect = [window frameRectForContentRect:newRect];
        [window setFrame:frameRect display:NO];
        [view setFrame:frameRect];
        [window setMovable:YES]; // XXX - this shouldn't be necessary
        
        mousePositionPin = [self registerOutputPin:@"mousePosition" withType:kJMXPointPin];
        controller = [[JMXScreenController alloc] initWithView:view delegate:self];
        self.label = @"OpenGLScreen";
        [window makeKeyAndOrderFront:[NSApplication sharedApplication]];
        //[window orderBack:self];
    }
    return self;
    
}

- (NSColor *)backgroundColor
{
    @synchronized(self) {
        return [[backgroundColor retain] autorelease];
    }
}

- (void)setBackgroundColor:(NSColor *)newBackgroundColor
{
    @synchronized(self) {
        if (backgroundColor != newBackgroundColor) {
            [backgroundColor release];
            backgroundColor = [newBackgroundColor retain];
            view.backgroundColor = backgroundColor;
            [view reshape];
        }
    }
}

- (void)setSize:(JMXSize *)newSize
{
    //@synchronized(self) {
    if (![newSize isEqual:size]) {
        [super setSize:newSize];
        [controller setSize:newSize];
    }
    //}
}

- (void)drawFrame:(CIImage *)frame
{
    [super drawFrame:frame];
    if (view) {
        view.currentFrame = frame;
    }
}

- (void)dealloc
{
    [self disconnectAllPins];
    [window release];
    if (view) {
        [view release];
        view = nil;
    }
    if (controller)
        [controller release];
    controller = nil;
    [super dealloc];
}

- (BOOL)fullScreen
{
    @synchronized(self) {
        return fullScreen;
    }
}

- (void)setFullScreen:(BOOL)yesOrNo
{
    @synchronized(self) {
        if (fullScreen == yesOrNo)
            return;
        fullScreen = yesOrNo;
        [view performSelectorOnMainThread:@selector(toggleFullScreen:)
                               withObject:self
                            waitUntilDone:YES];
    }
    
}

- (BOOL)invertYCoordinates
{
    if (view)
        return view.invertYCoordinates;
    return NO;
}

- (void)setInvertYCoordinates:(BOOL)yesOrNo
{
    if (view)
        view.invertYCoordinates = yesOrNo;
}

#pragma mark -
#pragma mark JMXScreenControllerDelegate

static void translateScreenCoordinates(JMXOpenGLView *view, NSSize screenSize, NSSize frameSize,
                                       CGFloat screenX, CGFloat screenY,
                                       CGFloat &frameX, CGFloat &frameY)
{
    

    if (![view isInFullScreenMode]) { // XXX - WTF
        NSRect frameRect = [view.window frameRectForContentRect:NSRectFromCGRect(CGRectMake(0, 0, frameSize.width, frameSize.height))];
        screenY += (frameRect.size.height - frameSize.height)/2;
    }

    
    CGFloat width = screenSize.width;
    CGFloat height = screenSize.height;
    CGFloat scaledWidth = 0;
    CGFloat scaledHeight = 0;
    if (width > height) {
        scaledHeight = height;
        scaledWidth = floor((scaledHeight*frameSize.width)/frameSize.height);
    } else {
        scaledWidth = width;
        scaledHeight = floor((scaledWidth*frameSize.height)/frameSize.width);
    }
    
    CGFloat xFactor = frameSize.width / scaledWidth;
    CGFloat yFactor = frameSize.height / scaledHeight;
    frameX = (screenX * xFactor) - ((screenSize.width - scaledWidth)/4);
    if (view.invertYCoordinates)
        frameY = frameSize.height - (screenY * yFactor);
    else
        frameY = (screenY * yFactor);
}

- (void)mouseUp:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    if (ctx) {
        CGFloat x, y;

        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:@"mouseup"
                                                                  target:nil
                                                                listener:nil
                                                                 capture:NO] autorelease];
        NSPoint location = event.locationInWindow;
        
        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        [ctx dispatchEvent:mouseEvent];
    }
}

- (void)mouseDown:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    if (ctx) {
        CGFloat x, y;

        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:@"mousedown"
                                                                  target:nil
                                                                listener:nil
                                                                 capture:NO] autorelease];
        NSPoint location = event.locationInWindow;

        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        
        [ctx dispatchEvent:mouseEvent];
    }
}

- (void)mouseMoved:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    NSPoint location = event.locationInWindow;
    if (ctx) {
        //JMXScriptEntity *scriptEntity = ctx.scriptEntity;
        uint64_t currentEventTime =  CVGetCurrentHostTime();
        if (lastEventType == kEventTypeMouseMove &&
            currentEventTime - lastEventTime < 1e9/kMaxEventsPerSecond)
        {
            return;
        }
        CGFloat x, y;

        [lastEventType release];
        lastEventType = kEventTypeMouseMove;
        lastEventTime = currentEventTime;
        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:@"mousemove"
                              target:nil
                            listener:nil
                             capture:NO] autorelease];
        
        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        
        [ctx dispatchEvent:mouseEvent];
    }
    mousePositionPin.data = [JMXPoint pointWithX:location.x Y:location.y];
}

- (void)mouseEntered:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    if (ctx) {
        CGFloat x, y;

        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:@"mouseenter"
                                                                  target:nil
                                                                listener:nil
                                                                 capture:NO] autorelease];
        NSPoint location = event.locationInWindow;
        
        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        [ctx dispatchEvent:mouseEvent];
    }
}

- (void)mouseExited:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    if (ctx) {
        CGFloat x, y;

        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:@"mouseleave"
                                                                  target:nil
                                                                listener:nil
                                                                 capture:NO] autorelease];
        NSPoint location = event.locationInWindow;
        
        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        [ctx dispatchEvent:mouseEvent];
    }
}

- (void)mouseDragged:(NSEvent *)event inView:(JMXOpenGLView *)aView
{
    if (ctx) {
        //JMXScriptEntity *scriptEntity = ctx.scriptEntity;
        uint64_t currentEventTime =  CVGetCurrentHostTime();
        if (lastEventType == kEventTypeMouseDragged &&
            currentEventTime - lastEventTime < 1e9/kMaxEventsPerSecond)
        {
            return;
        }
        lastEventType = kEventTypeMouseDragged;
        lastEventTime = currentEventTime;
        
        CGFloat x, y;

        NSPoint location = event.locationInWindow;
        translateScreenCoordinates(aView, aView.frame.size, aView.frameSize.nsSize,
                                   location.x, location.y, x, y);
        JMXMouseEvent *mouseEvent = [[[JMXMouseEvent alloc] initWithType:kEventTypeMouseDragged
                                                                  target:nil
                                                                listener:nil
                                                                 capture:NO] autorelease];
        

        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        [ctx dispatchEvent:mouseEvent];
        // propagate a 'mousemove' event as well to be DOM compliant
        mouseEvent = [[[JMXMouseEvent alloc] initWithType:kEventTypeMouseMove
                                                   target:nil
                                                 listener:nil
                                                  capture:NO] autorelease];
        
        
        mouseEvent.screenX = x;
        mouseEvent.screenY = y;
        [ctx dispatchEvent:mouseEvent];
    }
}

- (void)keyUp:(NSEvent *)event inView:(JMXOpenGLView *)view
{
    if (ctx) {
        JMXKeyboardEvent *kbdEvent = [[[JMXKeyboardEvent alloc] initWithType:@"keyup"
                                                                      target:nil
                                                                    listener:nil
                                                                     capture:NO] autorelease];
        kbdEvent.str = [event characters];
        kbdEvent.key = [event charactersIgnoringModifiers];
        NSUInteger modifierFlags = event.modifierFlags;
        kbdEvent.shiftKey = modifierFlags&NSShiftKeyMask;
        kbdEvent.altKey = modifierFlags&NSAlternateKeyMask;
        kbdEvent.ctrlKey = modifierFlags&NSControlKeyMask;
        kbdEvent.metaKey = modifierFlags&NSCommandKeyMask;
        [ctx dispatchEvent:kbdEvent];
    }
}

- (void)keyDown:(NSEvent *)event inView:(JMXOpenGLView *)glView
{
    if ([event keyCode] == 3 && [event modifierFlags]&NSCommandKeyMask) { // %-f to switch fullscreen
        [glView toggleFullScreen:self];
        [controller setWindow:[glView window]];
    }
    if (ctx) {
        JMXKeyboardEvent *kbdEvent = [[[JMXKeyboardEvent alloc] initWithType:@"keydown"
                                                                   target:nil
                                                                 listener:nil
                                                                  capture:NO] autorelease];
        kbdEvent.str = [event characters];
        kbdEvent.key = [event charactersIgnoringModifiers];
        NSUInteger modifierFlags = event.modifierFlags;
        kbdEvent.shiftKey = modifierFlags&NSShiftKeyMask;
        kbdEvent.altKey = modifierFlags&NSAlternateKeyMask;
        kbdEvent.ctrlKey = modifierFlags&NSControlKeyMask;
        kbdEvent.metaKey = modifierFlags&NSCommandKeyMask;
        [ctx dispatchEvent:kbdEvent];
        if (kbdEvent.str.length) {
            kbdEvent.type = @"keypress";
            [ctx dispatchEvent:kbdEvent];
        }
    }
}

#pragma mark -
#pragma mark V8
+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    v8::Persistent<FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("OpenGLScreen"));
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("fullScreen"), GetBoolProperty, SetBoolProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("invertYCoordinates"), GetBoolProperty, SetBoolProperty);

    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    NSDebug(@"JMXOpenGLScreen objectTemplate created");
    return objectTemplate;
}

@end
