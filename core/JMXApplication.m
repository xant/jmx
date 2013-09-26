//
//  JMXApplication.m
//  JMX
//
//  Created by xant on 7/11/13.
//  Copyright (c) 2013 Dyne.org. All rights reserved.
//

#import "JMXApplication.h"
#import "JMXContext.h"
#import "JMXVideoMixer.h"
#import "JMXQtMovieEntity.h"
#import "JMXOpenGLScreen.h"
#import "JMXImageEntity.h"
#import "JMXQtVideoCaptureEntity.h"
#import "JMXAudioFileEntity.h"
#import "JMXCoreAudioOutput.h"
#import "JMXQtAudioCaptureEntity.h"
#import "JMXAudioMixer.h"
#import "JMXAudioSpectrumAnalyzer.h"
#import "JMXCoreImageFilter.h"
#import "JMXTextEntity.h"
#import "JMXScriptFile.h"
#import "JMXScriptLive.h"
//#import "JMXPhidgetEncoderEntity.h"
#import "JMXAudioToneGenerator.h"
#import "JMXHIDInputEntity.h"
#import "JMXAudioDumper.h"
#import "CIAlphaBlend.h"
#import "CIAlphaFade.h"
#import "CIAdditiveBlur.h"

int verbose = LOG_INFO;

@implementation JMXApplication

- (id)init
{
    self = [super init];
    if (self) {
        argv = [[NSMutableArray alloc] initWithCapacity:10];
        self.appName = @"JMX";
    }
    return self;
}

- (void)logMessage:(NSString *)message, ...
{
    va_list args;
    va_start(args, message);
    [self logMessage:message args:args];
    va_end(args);
}

- (void)logMessage:(NSString *)message args:(va_list)args
{
    NSLogv(message, args);
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
	JMXContext *sharedContext = [JMXContext sharedContext];
	[sharedContext registerClass:[JMXVideoMixer class]];
	[sharedContext registerClass:[JMXImageEntity class]];
	[sharedContext registerClass:[JMXOpenGLScreen class]];
	[sharedContext registerClass:[JMXQtVideoCaptureEntity class]];
	[sharedContext registerClass:[JMXQtMovieEntity class]];
	[sharedContext registerClass:[JMXCoreAudioOutput class]];
	[sharedContext registerClass:[JMXQtAudioCaptureEntity class]];
	[sharedContext registerClass:[JMXAudioFileEntity class]];
	[sharedContext registerClass:[JMXAudioMixer class]];
    [sharedContext registerClass:[JMXAudioSpectrumAnalyzer class]];
    [sharedContext registerClass:[JMXCoreImageFilter class]];
	[sharedContext registerClass:[JMXTextEntity class]];
    [sharedContext registerClass:[JMXScriptFile class]];
    [sharedContext registerClass:[JMXScriptLive class]];
    [sharedContext registerClass:[JMXHIDInputEntity class]];
    [sharedContext registerClass:[JMXAudioToneGenerator class]];
    [sharedContext registerClass:[JMXAudioDumper class]];
    
    //[QTMovie initialize];
    [CIAlphaFade class];
    [CIAlphaBlend class]; // trigger initialize to have the filter registered and available in the videomixer
    [CIAdditiveBlur class];
//    if (CPhidgetEncoder_create != NULL) {
//        // XXX - exception case for weakly linked Phidget library
//        //       if it's not available at runtime we don't want to register the phidget-related entities
//        //       or the application will crash when the user tries accessing them
//        [sharedContext registerClass:[JMXPhidgetEncoderEntity class]];
//    }
	INFO("Registered %ul entities", (unsigned int)[[sharedContext registeredClasses] count]);
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    if (argv.count) {
        JMXScriptFile *file = [[[JMXScriptFile alloc] init] autorelease];
        
        file.active = YES;
        _batchMode = YES;
        NSString *filePath = [argv objectAtIndex:0];
        [argv removeObjectAtIndex:0];
        file.arguments = argv;
        file.path = filePath;
    } else {
        _batchMode = NO;
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [argv addObject:filename];
    if (argv.count == 1)
        return YES;
    return NO;
}

@end
