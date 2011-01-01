//
//  JMXQtVideoLayer.m
//  JMX
//
//  Created by Igor Sutton on 8/5/10.
//  Copyright (c) 2010 Dyne.org. All rights reserved.
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

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#ifndef __x86_64
#import  <QuickTime/QuickTime.h>
#endif
#define __JMXV8__
#import "JMXQtMovieEntity.h"
#import "JMXScript.h"
#import "JMXThreadedEntity.h"

JMXV8_EXPORT_ENTITY_CLASS(JMXQtMovieEntity);

#ifndef __x86_64
/* Utility to set a SInt32 value in a CFDictionary
 */
static OSStatus SetNumberValue(CFMutableDictionaryRef inDict,
                               CFStringRef inKey,
                               SInt32 inValue)
{
    CFNumberRef number;
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &inValue);
    if (NULL == number) return coreFoundationUnknownErr;
    
    CFDictionarySetValue(inDict, inKey, number);
    
    CFRelease(number);
    
    return noErr;
}
#endif

@implementation JMXQtMovieEntity

@synthesize moviePath, paused, repeat;

- (id)init
{
    self = [super init];
    if (self) {
        movie = nil;
        moviePath = nil;
        repeat = YES;
        paused = NO;
        movieFrequency = 0;
        self.name = @"QtMovieFile";
        [self registerInputPin:@"path" withType:kJMXStringPin andSelector:@"setMoviePath:"];
        [self registerInputPin:@"repeat" withType:kJMXBooleanPin andSelector:@"setBooleanPin:"];
        [self registerInputPin:@"paused" withType:kJMXBooleanPin andSelector:@"setBooleanPin:"];
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        if (threadedEntity)
            return threadedEntity;
        // TODO - Error Messages
        [self dealloc];
    }
    return nil;
}

#ifndef __x86_64
- (void)setupPixelBuffer
{
    OSStatus err;
    CGLContextObj         glContext;
    CGLPixelFormatObj pFormat;
    GLint npix;
    const int attrs[2] = { kCGLPFADoubleBuffer, 0};
    err = CGLChoosePixelFormat ((CGLPixelFormatAttribute *)attrs,
                                 &pFormat,
                                 &npix
                                 );
    err = CGLCreateContext(pFormat , NULL, &glContext);
    
    /* Create QT Visual context */
    
    // Pixel Buffer attributes
    CFMutableDictionaryRef pixelBufferOptions = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                          &kCFTypeDictionaryKeyCallBacks,
                                                                          &kCFTypeDictionaryValueCallBacks);
    
    // the pixel format we want (freej require BGRA pixel format)
    SetNumberValue(pixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, k32ARGBPixelFormat);
    
    // size
    SetNumberValue(pixelBufferOptions, kCVPixelBufferWidthKey, size.width);
    SetNumberValue(pixelBufferOptions, kCVPixelBufferHeightKey, size.height);
    
    // alignment
    SetNumberValue(pixelBufferOptions, kCVPixelBufferBytesPerRowAlignmentKey, 1);
    // QT Visual Context attributes
    CFMutableDictionaryRef visualContextOptions = CFDictionaryCreateMutable(kCFAllocatorDefault, 0,
                                                                            &kCFTypeDictionaryKeyCallBacks,
                                                                            &kCFTypeDictionaryValueCallBacks);
    // set the pixel buffer attributes for the visual context
    CFDictionarySetValue(visualContextOptions,
                         kQTVisualContextPixelBufferAttributesKey,
                         pixelBufferOptions);
    CFRelease(pixelBufferOptions);
    
    err = QTOpenGLTextureContextCreate(kCFAllocatorDefault, glContext,
                                       CGLGetPixelFormat(glContext), visualContextOptions, &qtVisualContext);
    CGLReleaseContext(glContext);
    
    CFRelease(visualContextOptions);
}
#endif

- (void)setMoviePath:(NSString *)path
{
    if (moviePath)
        [self close];
    [self open:path];
}

- (BOOL)open:(NSString *)file
{
    if (file != nil) {
        NSError *error;
        NSLog(@"moviePath: %@", file);
        @synchronized(self) {
            if (movie)
                [movie release];
            // Setter already releases and retains where appropriate.
            movie = [[QTMovie movieWithFile:file error:&error] retain];
            
            if (!movie) {
                NSLog(@"Got error: %@", error);
                return NO;
            }
            
#if 0
            NSArray *tracks = [qtMovie tracks];
            bool hasVideo = NO;
            for (NSUInteger i = 0; i < [tracks count]; i ++) {
                QTTrack *track = [tracks objectAtIndex:i];
                NSString *type = [track attributeForKey:QTTrackMediaTypeAttribute];
                if (![type isEqualToString:QTMediaTypeVideo]) {
                    [track setEnabled:NO];
#ifndef __x86_64
                    DisposeMovieTrack([track quickTimeTrack]);
#endif
                } else {
                    hasVideo = YES;
                }
            }
            if (!hasVideo) {
                qtMovie = nil;
                [lock unlock];
                return NO;
            }
#endif
            NSLog(@"movie: %@", movie);
            NSArray* videoTracks = [movie tracksOfMediaType:QTMediaTypeVideo];
            QTTrack* firstVideoTrack = [videoTracks objectAtIndex:0];
            QTMedia* media = [firstVideoTrack media];
            QTTime qtTimeDuration = [[media attributeForKey:QTMediaDurationAttribute] QTTimeValue];
            long sampleCount = [[media attributeForKey:QTMediaSampleCountAttribute] longValue];
            // we can set the frequency to be exactly the same as fps ... since it's useles
            // to have an higher signaling frequency in the case of an existing movie. 
            // In any case we won't have more 'unique' frames than the native movie fps ... so if signaling 
            // the frames more often we will just send the same image multiple times (wasting precious cpu time)
            if (sampleCount > 1) { // check if we indeed have a sequence of frames
                self.frequency = [NSNumber numberWithDouble:(sampleCount+1)/(qtTimeDuration.timeValue/qtTimeDuration.timeScale)];
                movieFrequency = (sampleCount+1)/(qtTimeDuration.timeValue/qtTimeDuration.timeScale);
            } else {// or if it's just a still image, set the frequency to 1 sec
                self.frequency = [NSNumber numberWithDouble:1]; // XXX
                movieFrequency = 0;
            }
                
            // set the layer size to the native movie size
            // scaling is a quite expensive operation and the user 
            // must be aware he is doing that (so better waiting for him
            // to set a different layer size by using the proper input pin)
            NSSize movieSize = [firstVideoTrack apertureModeDimensionsForMode:@"QTMovieApertureModeClean"];
            size = [[JMXSize sizeWithNSSize:movieSize] retain];
            fpsPin.data = self.frequency;
            NSArray *path = [file componentsSeparatedByString:@"/"];
            self.label = [path lastObject];
#ifndef __x86_64
            if (qtVisualContext) {
                QTVisualContextTask(qtVisualContext);
            } else {
                [self setupPixelBuffer];
                OSStatus err = SetMovieVisualContext([movie quickTimeMovie], qtVisualContext);
                if (err != noErr) {
                    // TODO - Error Messages
                }
            }
#endif
        }
        if (moviePath)
            [moviePath release];
        moviePath = [file copy];
        return YES;
    }
    return NO;
}

- (void)close {
    // TODO - IMPLEMENT
}

- (void)dealloc {
    if (movie)
        [movie release];
#ifndef __x86_64
    if(qtVisualContext)
        QTVisualContextRelease(qtVisualContext);
#endif
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    CIImage* frame;
    NSError* error = nil;
    CVPixelBufferRef pixelBuffer = NULL;
    if (movie) {
        [QTMovie enterQTKitOnThread];
        QTTime now = [movie currentTime];
        @synchronized(self) {
            if (!paused) {
                if (currentFrame) {
                    [currentFrame release];
                    currentFrame = nil;
                }
                uint64_t delta = self.previousTimeStamp
                               ? (timeStamp - self.previousTimeStamp) / 1e9 * now.timeScale
                               : now.timeScale / [fps doubleValue];

                uint64_t step = movieFrequency
                              ? [fps doubleValue] * delta / movieFrequency
                              : 0;
                
                // Calculate the next frame we need to provide.
                now.timeValue += step;

                if (QTTimeCompare(now, [movie duration]) == NSOrderedAscending) {
                    [movie setCurrentTime:now];
                } else { // the movie is ended
                    if (repeat) { // check if we need to rewind and re-start extracting frames
                        [movie gotoBeginning];
                        now.timeValue = 0;
                    } else {
                        [self stop];
                        return [super tick:timeStamp]; // we still want to propagate the signal
                    }
                }
#ifdef __x86_64
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSValue valueWithSize:self.size.nsSize],
                                       QTMovieFrameImageSize,
                                       QTMovieFrameImageTypeCVPixelBufferRef,
                                       QTMovieFrameImageType,
#if MAC_OS_X_VERSION_MAX_ALLOWED > MAC_OS_X_VERSION_10_5
                                       [NSNumber numberWithBool:YES],
                                       QTMovieFrameImageSessionMode,
#endif
                                       nil]; 
                pixelBuffer = (CVPixelBufferRef)[movie frameImageAtTime:now 
                                                         withAttributes:attrs error:&error];
#else
                if(qtVisualContext)
                {        
                    QTVisualContextCopyImageForTime(qtVisualContext,
                                                    NULL,
                                                    NULL,
                                                    &pixelBuffer);
                }
#endif                
                frame = [CIImage imageWithCVImageBuffer:pixelBuffer];
#ifndef __x86_64
                CVPixelBufferRelease(pixelBuffer);
                MoviesTask([movie quickTimeMovie], 0);
                QTVisualContextTask(qtVisualContext);
#endif
                if (frame)
                    currentFrame = [frame retain];
                else if (error)
                    NSLog(@"%@\n", error);
            } 
        }
        [QTMovie exitQTKitOnThread];
    }
    [super tick:timeStamp]; // let super notify output pins
}

#pragma mark -

- (NSString *)displayName
{
    return [NSString stringWithFormat:@"%@", self.moviePath];
}

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"avi", @"mov", @"mp4", @"pdf", @"html", nil];
}

- (void)setSize:(JMXSize *)newSize
{
    return [super setSize:newSize];
}

- (void)setRepeatPin:(NSNumber *)newValue
{
    self.repeat = [newValue boolValue];
}

- (void)setPausedPin:(NSNumber *)newValue
{
    self.paused = [newValue boolValue];
}

#pragma mark <JMXPinOwner>

- (id)provideDataToPin:(JMXPin *)aPin
{
    // TODO - use introspection to determine the return type of a message
    //        to generalize using encapsulation in NSNumber/NSData/NSValue 
    if ([aPin.name isEqualTo:@"repeat"]) {
        return [NSNumber numberWithBool:self.repeat];
    } else if ([aPin.name isEqualTo:@"paused"]) {
        return [NSNumber numberWithBool:self.paused];
    } else {
        return [super provideDataToPin:aPin];
    }
    return nil;
}

#pragma mark V8
using namespace v8;

- (void)jsInit:(NSValue *)argsValue
{
    v8::Arguments *args = (v8::Arguments *)[argsValue pointerValue];
    if (args->Length()) {
        v8::Handle<Value> arg = (*args)[0];
        v8::String::Utf8Value value(arg);
        if (*value)
            [self open:[NSString stringWithUTF8String:*value]];
    }
}

static v8::Handle<Value>Open(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    BOOL ret = [entity open:[NSString stringWithUTF8String:*value]];
    return v8::Boolean::New(ret);
}

static v8::Handle<Value>Close(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    [entity close];
    return v8::Undefined();
}

static v8::Handle<Value>SupportedFileTypes(const Arguments& args)
{
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *supportedTypes = nil;
    JMXQtMovieEntity *movieFile = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(1);
    if (movieFile) {
        supportedTypes = [[movieFile class] supportedFileTypes];
    } else {
        Class<JMXFileRead> objcClass = (Class)External::Unwrap(args.Holder()->Get(String::NewSymbol("_objcClass")));
        supportedTypes = [objcClass supportedFileTypes];
    }
    v8::Handle<Array> list = v8::Array::New([supportedTypes count]);
    for (int i = 0; i < [supportedTypes count]; i++)
        list->Set(Number::New(i), String::New([[supportedTypes objectAtIndex:i] UTF8String]));
    [pool release];
    return handleScope.Close(list);
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = [super jsObjectTemplate];
    entityTemplate->SetClassName(String::New("QtMovieFile"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("open", FunctionTemplate::New(Open));
    classProto->Set("close", FunctionTemplate::New(Close));
    classProto->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
    return entityTemplate;
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    [super jsRegisterClassMethods:constructor]; // let our super register its methods (if any)
    constructor->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
}
@end
