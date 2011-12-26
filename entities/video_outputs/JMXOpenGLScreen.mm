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
#import <AppKit/AppKit.h>
//#import <Carbon/Carbon.h>

JMXV8_EXPORT_NODE_CLASS(JMXOpenGLScreen);

@interface JMXOpenGLView : NSOpenGLView {
    CIImage *currentFrame;
    CIContext *ciContext;
    CVDisplayLinkRef    displayLink; // the displayLink that runs the show
    CGDirectDisplayID   viewDisplayID;
    uint64_t lastTime;
    BOOL fullScreen;
    NSWindow *myWindow;
    BOOL needsResize;
    NSRecursiveLock *lock;

#if MAC_OS_X_VERSION_10_6
    CGDisplayModeRef     savedMode;
#else
    CFDictionaryRef      savedMode;
#endif
    JMXSize *frameSize;
}

@property (retain) CIImage *currentFrame;

- (void)setSize:(NSSize)size;
- (void)cleanup;
- (void)renderFrame:(uint64_t)timeStamp;

@end

static CVReturn renderCallback(CVDisplayLinkRef displayLink, 
                               const CVTimeStamp *inNow, 
                               const CVTimeStamp *inOutputTime, 
                               CVOptionFlags flagsIn, 
                               CVOptionFlags *flagsOut, 
                               void *displayLinkContext)
{    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    [(JMXOpenGLView*)displayLinkContext renderFrame:inNow->hostTime];
    [pool drain];
    return noErr;
}

@implementation JMXOpenGLView

@synthesize currentFrame;

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
        lastTime = 0;
        fullScreen = NO;
        myWindow = nil;
        [self setSize:frameRect.size];
        lock = [[NSRecursiveLock alloc] init];
    }
    return self;
}

- (void)prepareOpenGL
{
    if (ciContext == nil) {

        [super prepareOpenGL];
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        ciContext = [[CIContext contextWithCGLContext:(CGLContextObj)[[self openGLContext] CGLContextObj]
                                          pixelFormat:(CGLPixelFormatObj)[[self pixelFormat] CGLPixelFormatObj]
                                           colorSpace:colorSpace
                                              options:nil] retain];
        CGColorSpaceRelease(colorSpace);

        // Create display link 
        CGOpenGLDisplayMask    totalDisplayMask = 0;
        int            virtualScreen;
        GLint        displayMask;
        NSOpenGLPixelFormat    *openGLPixelFormat = [self pixelFormat];

        [self setNeedsDisplay:YES];
        viewDisplayID = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];  
        for (virtualScreen = 0; virtualScreen < [openGLPixelFormat  numberOfVirtualScreens]; virtualScreen++)
        {
            [openGLPixelFormat getValues:&displayMask forAttribute:NSOpenGLPFAScreenMask forVirtualScreen:virtualScreen];
            totalDisplayMask |= displayMask;
        }
        CVReturn ret = CVDisplayLinkCreateWithCGDisplay(viewDisplayID, &displayLink);
        if (ret != noErr) {
            // TODO - Error Messages
        }
        // Set up display link callbacks
        NSLog(@"Creating CVDisplayLink");
        CVDisplayLinkSetOutputCallback(displayLink, renderCallback, self);
        CVDisplayLinkStart(displayLink);
        [self setNeedsDisplay:YES];
    }
}

- (void)dealloc
{
    NSLog(@"Releasing CVDisplayLink");
    CVDisplayLinkStop(displayLink);
    CVDisplayLinkRelease(displayLink);
    [self cleanup];
    [lock release];
    [super dealloc];
}

- (void)renderFrame:(uint64_t)timeStamp
{
    if (timeStamp-lastTime < 1e9/30) // HC
        return;
    lastTime = timeStamp;
    [lock lock];
    if (needsResize) {
        NSRect actualRect = [[self window] contentRectForFrameRect:[self frame]];
        NSRect newRect = NSMakeRect(0, 0, frameSize.width, frameSize.height);
        //[self setBounds:newRect];
        newRect.origin.x = actualRect.origin.x;
        newRect.origin.y = actualRect.origin.y;
        NSRect frameRect;
        frameRect = [[self window] frameRectForContentRect:newRect];
        
        
        [[self window] setFrame:frameRect display:NO];
        [self setFrame:frameRect];
        [[self window] setMovable:YES]; // XXX - this shouldn't be necessary
        needsResize = NO;
    }
    //if (CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]) != kCGLNoError)
      //  NSLog(@"Could not lock CGLContext");
    [[self openGLContext] makeCurrentContext];
    CIImage *image = [self.currentFrame retain];
    if (image && ciContext) {
        CGRect sourceRect = { { 0, 0, }, { frameSize.width, frameSize.height } };
        CGRect screenFrame = NSRectToCGRect([[self window] contentRectForFrameRect:[self frame]]);
        CGFloat scaledWidth, scaledHeight;
        CGFloat width = screenFrame.size.width;
        CGFloat height = screenFrame.size.height;
        if (width > height) {
            scaledHeight = height;
            scaledWidth = (scaledHeight*frameSize.width)/frameSize.height;
        } else {
            scaledWidth = width;
            scaledHeight = (scaledWidth*frameSize.height)/frameSize.width;
        }
        CGRect  destinationRect = CGRectMake(screenFrame.origin.x, screenFrame.origin.y,
                                             scaledWidth, scaledHeight);
        
        
        if (fullScreen)
        {   
            destinationRect.origin.x = (width-scaledWidth)/2;
            destinationRect.origin.y = (height-scaledHeight)/2;
        }

        // XXX - this seems unnecessary (at least on lion ... and we don't care of retro compatibility)
        // clean the OpenGL context 
        //glClearColor(0.0, 0.0, 0.0, 0.0);         
        //glClear(GL_COLOR_BUFFER_BIT);
        
        // XXX - it seems that since osx 10.7 different CVDisplayLink callbacks,
        //       registered for different opengl contexts but on the same physical display
        //       are called in different threads.
        //       Since we access the same CIImage from different threads,
        //       to draw it on different contextes and possibly applying different
        //       filters, we need to protect the whole rendering steps in a critical
        //       section (synchronized against our class itself to make it a g
        //       lobal lock for all living opengl screens)
        @synchronized([self class]) { // BIG LOCK
            [ciContext drawImage:image inRect:destinationRect fromRect:sourceRect];
            [image release];
            [[self openGLContext] flushBuffer];
        }
    }
    [self setNeedsDisplay:NO];
    [lock unlock];
    //CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}

- (void)drawRect:(NSRect)rect
{
    // we do rendering in our own thread... we don't want
    // it to happen in the main application thread
    [self setNeedsDisplay:NO];
}


// Called by Cocoa when the view's visible rectangle or bounds change.
- (void)reshape
{
    if (CGLLockContext((CGLContextObj)[[self openGLContext] CGLContextObj]) != kCGLNoError)
         NSLog(@"Could not lock CGLContext");
    [lock lock];
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
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    [[self openGLContext] flushBuffer];
    [lock unlock];
    CGLUnlockContext((CGLContextObj)[[self openGLContext] CGLContextObj]);
}


- (void)cleanup
{
    [lock lock];
    if (ciContext) {
        [ciContext release];
        ciContext = nil;
    }
    if (frameSize)
        [frameSize release];
    frameSize = nil;
    //self.currentFrame = nil;
    [lock unlock];  
}

- (void)setSize:(NSSize)size
{
    [lock lock];
    NSRect actualRect = [[self window] contentRectForFrameRect:[self frame]];
    // XXX - we actually don't allow setting a 0-size (for neither width nor height)
    if (size.width && size.height &&
        (size.width != actualRect.size.width ||
         size.height != actualRect.size.height))
    {
        if (frameSize)
            [frameSize release];
        frameSize = [[JMXSize sizeWithNSSize:size] retain];
        needsResize = YES;
    }
    [lock unlock];
}

- (IBAction)toggleFullScreen:(id)sender
{
    if ([self isInFullScreenMode] || fullScreen) {
        [self exitFullScreenModeWithOptions:nil];
        fullScreen = NO;
    } else {
        CGDisplayModeRef newMode;
        bool exactMatch;
        CGDirectDisplayID currentDisplayID = (CGDirectDisplayID)[[[[[self window] screen] deviceDescription] objectForKey:@"NSScreenNumber"] intValue];  

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
                continue;
            
            if((CGDisplayModeGetWidth(mode) >= frameSize.width) && (CGDisplayModeGetHeight(mode) >= frameSize.height))
            {
                newMode = mode;
                exactMatch = true;
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
                    continue;
                
                if((CGDisplayModeGetWidth(mode) >= frameSize.width) && (CGDisplayModeGetHeight(mode) >= frameSize.height))
                {
                    newMode = mode;
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
        fullScreen = YES;
    }
    [self reshape];
}
@end


@interface JMXScreenController : NSWindowController {
    NSMutableArray *_keyEvents;
    JMXOpenGLView *_view;
}
- (NSDictionary *)getEvent;
@end

@implementation JMXScreenController

- (id)initWithView:(JMXOpenGLView *)view
{
    _keyEvents = [[NSMutableArray arrayWithCapacity:100] retain];
    _view = view;
    return [super initWithWindow:[_view window]];
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

@end

@implementation JMXOpenGLScreen

@synthesize window, view;

- (id)initWithSize:(NSSize)screenSize
{
    self = [super initWithSize:screenSize];
    if (self) {
        NSRect frame = NSMakeRect(0, 0, size.width, size.height);
        view = [[JMXOpenGLView alloc] initWithFrame:frame];
        window = [[NSWindow alloc] initWithContentRect:frame                                          
                                             styleMask:NSTitledWindowMask|NSMiniaturizableWindowMask
                                               backing:NSBackingStoreBuffered 
                                                 defer:NO];
        [[window contentView] addSubview:view];
        [window setReleasedWhenClosed:NO];
        [window setIsVisible:YES];
        controller = [[JMXScreenController alloc] initWithView:view];
        self.label = @"OpenGLScreen";
        //[window orderBack:self];
    }
    return self;
    
}

- (void)setSize:(JMXSize *)newSize
{
    //@synchronized(self) {
    if (![newSize isEqual:size]) {
        [super setSize:newSize];
        [view setSize:[newSize nsSize]];
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

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    v8::Persistent<FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);  
    objectTemplate->SetClassName(String::New("OpenGLScreen"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    NSLog(@"JMXOpenGLScreen objectTemplate created");
    return objectTemplate;
}

@end
