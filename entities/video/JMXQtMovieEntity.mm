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
#include <Carbon/Carbon.h>

#define __JMXV8__
#import "JMXQtMovieEntity.h"
#import "JMXScript.h"
#import "JMXThreadedEntity.h"
#import "JMXAttribute.h"
#include <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>

JMXV8_EXPORT_NODE_CLASS(JMXQtMovieEntity);

@implementation JMXQtMovieEntity

@synthesize moviePath, paused, repeat, duration, sampleCount;

- (id)init
{
    self = [super init];
    if (self) {
        movie = nil;
        moviePath = nil;
        repeat = YES;
        paused = NO;
        movieFrequency = 0;
        self.label = @"QtMovieFile";
        [self registerInputPin:@"path" withType:kJMXStringPin andSelector:@"setMoviePath:"];
        [self registerInputPin:@"repeat" withType:kJMXBooleanPin andSelector:@"setRepeatPin:"];
        [self registerInputPin:@"paused" withType:kJMXBooleanPin andSelector:@"setPausedPin:"];
        if ([AVAssetReader class]) {
            JMXOutputPin *outputPin = [self registerOutputPin:@"audio" withType:kJMXAudioPin];
            outputPin.mode = kJMXPinModePassive;
        }
        [self addAttribute:[JMXAttribute attributeWithName:@"url" stringValue:@""]];
        JMXThreadedEntity *threadedEntity = [[JMXThreadedEntity threadedEntity:self] retain];
        if (threadedEntity)
            return (JMXQtMovieEntity *)threadedEntity;
        // TODO - Error Messages
        [self dealloc];
    }
    return nil;
}

- (NSString *)moviePath
{
    @synchronized(self) {
        return moviePath;
    }
}

- (void)setMoviePath:(NSString *)path
{
    @synchronized(self) {
        if (moviePath)
            [self close];
        [self open:path];
    }
}

- (void)fillAudioBuffer
{
    CMSampleBufferRef sample = [audioOutput copyNextSampleBuffer];
    while (sample) {
        AudioBufferList  localBufferList;
        CMBlockBufferRef blockBuffer;
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sample,
                                                                NULL,
                                                                &localBufferList,
                                                                sizeof(localBufferList),
                                                                NULL,
                                                                NULL,
                                                                kCMSampleBufferFlag_AudioBufferList_Assure16ByteAlignment,
                                                                &blockBuffer);
        
        CMFormatDescriptionRef descriptionRef = CMSampleBufferGetFormatDescription(sample);
        AudioStreamBasicDescription *desc = (AudioStreamBasicDescription *)CMAudioFormatDescriptionGetStreamBasicDescription(descriptionRef);
        
        size_t chunkSize = 512 * desc->mBytesPerFrame;
        @synchronized(samples) {
            for (int i = 0; i < localBufferList.mNumberBuffers; i++) {
                AudioBuffer *buffer = &localBufferList.mBuffers[i];
                int numFrames = buffer->mDataByteSize / desc->mBytesPerFrame;
                for (int n = 0; n < numFrames; n+= 512) {
                    AudioBuffer newBuffer;
                    newBuffer.mDataByteSize = (UInt32)MIN((numFrames - n) * desc->mBytesPerFrame, chunkSize);
                    newBuffer.mNumberChannels = buffer->mNumberChannels;
                    newBuffer.mData = (char *)buffer->mData + (n * desc->mBytesPerFrame);
                    JMXAudioBuffer *outputBuffer = [JMXAudioBuffer audioBufferWithCoreAudioBuffer:&newBuffer andFormat:desc];
                    [samples addObject:outputBuffer];
                }                        
            }
        }
        CMSampleBufferRef toRelease = sample;
        sample = [audioOutput copyNextSampleBuffer];
        CFRelease(toRelease);
    }
}

- (BOOL)_open:(NSString *)file
{
    if (file != nil) {
        NSError *error;
        NSLog(@"moviePath: %@", file);
        @synchronized(self) {
            if (movie)
                [movie release];
            if (movieAsset)
                [movieAsset release];

            movieAsset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:file] options:nil];

            // Setter already releases and retains where appropriate.
            movie = [[AVMovie movieWithURL:[NSURL fileURLWithPath:file] options:nil] retain];

            if (!movie) {
                NSLog(@"Can't open movie at url %@", file);
                return NO;
            }

            NSLog(@"movie: %@", movie);
            NSArray* videoTracks = [movie tracksWithMediaType:AVMediaTypeVideo];

            AVMovieTrack* firstVideoTrack = [videoTracks objectAtIndex:0];
            CMTimeRange timeRange = [firstVideoTrack timeRange];//mediaDataStorage];

            //AVTime qtTimeDuration = [[media attributeForKey:QTMediaDurationAttribute] QTTimeValue];
            duration = timeRange.duration.epoch; // XXX

            // we can set the frequency to be exactly the same as fps ... since it's useles
            // to have an higher signaling frequency in the case of an existing movie. 
            // In any case we won't have more 'unique' frames than the native movie fps ... so if signaling 
            // the frames more often we will just send the same image multiple times (wasting precious cpu time)
            self.frequency = [NSNumber numberWithFloat:firstVideoTrack.nominalFrameRate];
            movieFrequency = firstVideoTrack.nominalFrameRate;


            // set the layer size to the native movie size
            // scaling is a quite expensive operation and the user 
            // must be aware he is doing that (so better waiting for him
            // to set a different layer size by using the proper input pin)
            NSSize movieSize = firstVideoTrack.naturalSize;
            size = [[JMXSize sizeWithNSSize:movieSize] retain];
            fpsPin.data = self.frequency;
            NSArray *path = [file componentsSeparatedByString:@"/"];
            self.label = [path lastObject];

            OSAtomicCompareAndSwap64Barrier(sampleIndex, -1, &sampleIndex);
            if (samples) {
                @synchronized(samples) {
                    [samples removeAllObjects];
                }
                [samples release];
                samples = nil;
            }
            if (file && [AVAssetReader class]) {
                if (audioReader) {
                    [audioReader cancelReading];
                    [audioReader release];
                    audioReader = nil;
                }
                if (audioOutput) {
                    [audioOutput release];
                    audioOutput = nil;
                }
                AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:file]];
                audioReader = [[AVAssetReader assetReaderWithAsset:asset error:&error] retain];
                NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
                if (audioTracks.count) {
                    NSDictionary *audioSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                                   [NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey, 
                                                   [NSNumber numberWithFloat:44100.0],             AVSampleRateKey,
                                                   [NSNumber numberWithInt:2],                     AVNumberOfChannelsKey,
                                                   [NSNumber numberWithInt:32],                    AVLinearPCMBitDepthKey,
                                                   [NSNumber numberWithBool:NO],                   AVLinearPCMIsNonInterleaved,
                                                   [NSNumber numberWithBool:YES],                  AVLinearPCMIsFloatKey,
                                                   [NSNumber numberWithBool:NO],                   AVLinearPCMIsBigEndianKey,
                                                   nil];
                    NSArray *outputTracks = [NSArray arrayWithObject:[audioTracks objectAtIndex:0]];
                    audioOutput = [[AVAssetReaderAudioMixOutput
                                   assetReaderAudioMixOutputWithAudioTracks:outputTracks
                                   audioSettings:audioSettings] retain];
                    [audioReader addOutput:audioOutput];
                    samples = [[NSMutableArray alloc] initWithCapacity:65535];
                    [audioReader startReading];
                }
            }
        }
        
        if (moviePath)
            [moviePath release];
        moviePath = [file copy];
        self.active = YES;
        NSXMLNode *attr = [self attributeForName:@"url"];
        [attr setStringValue:moviePath];
        if (samples) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self fillAudioBuffer];
            }];
        }
        return YES;
    }
    self.active = NO;
    return NO;
}

- (BOOL)open:(NSString *)file {
    return [self _open:file];
}

- (void)close {
    // TODO - IMPLEMENT
}

- (void)seekTime:(int64_t)timeOffset
{
    OSAtomicCompareAndSwap64(seekOffset, timeOffset, &seekOffset);
}

- (void)seekAbsoluteTime:(int64_t)timeOffset
{
    OSAtomicCompareAndSwap64(absoluteTime, timeOffset, &absoluteTime);

}

- (void)seekFrame:(uint64_t)frameNum
{
    OSAtomicCompareAndSwap64(absoluteTime, frameNum * (duration/sampleCount) * 1e9, &absoluteTime);
}

- (void)dealloc {
    if (movie)
        [movie release];
    [samples release];
    [audioReader release];
    [audioOutput release];

    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    CIImage* frame;
    NSError* error = nil;
    CGImageRef pixelBuffer = NULL;
    @synchronized(self) {
        if (movie) {
            /*
            [QTMovie enterQTKitOnThread];
            */
            QTTime now = [movie currentTime];
            if (!paused) {
                if (currentFrame) {
                    [currentFrame release];
                    currentFrame = nil;
                }
                
                if (absoluteTime) {
                    now.timeValue = absoluteTime / 1e9 * now.timeScale;
                } else {
                    uint64_t delta = self.previousTimeStamp
                                   ? (timeStamp - self.previousTimeStamp) / 1e9 * now.timeScale
                                   : (now.timeScale / [fps doubleValue]);

                    uint64_t step = movieFrequency
                                  ? [fps doubleValue] * delta / movieFrequency
                                  : 0;
                    step += (seekOffset / 1e9 * now.timeScale);
                    // Calculate the next frame we need to provide.
                    now.timeValue += step;
                }
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
                if (now.timeValue == 0 || seekOffset || absoluteTime) {
                    OSAtomicCompareAndSwap64Barrier(sampleIndex, -1, &sampleIndex);
                }
                OSAtomicCompareAndSwap64(absoluteTime, 0, &absoluteTime);
                OSAtomicCompareAndSwap64(seekOffset, 0, &seekOffset);
                NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [NSValue valueWithSize:self.size.nsSize],
                                       QTMovieFrameImageSize,
                                       QTMovieFrameImageTypeCGImageRef,
                                       QTMovieFrameImageType,
                                       [NSNumber numberWithBool:YES],
                                       QTMovieFrameImageSessionMode,
                                       nil];
                pixelBuffer = (CGImageRef)[movie frameImageAtTime:now 
                                                         withAttributes:attrs error:&error];
                frame = [CIImage imageWithCGImage:pixelBuffer];


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

- (JMXAudioBuffer *)audio
{
    if (self.active && abs([self.fps doubleValue] - movieFrequency) < 0.1) {
        if (sampleIndex == -1) {
            [QTMovie enterQTKitOnThread];
            QTTime now = [movie currentTime];
            double nowSecs = now.timeValue / now.timeScale;
            
            sampleIndex = 44100.0 * nowSecs / 512;
            [QTMovie exitQTKitOnThread];
        }
        //return currentAudioSample;
        @synchronized(samples) {
            if (samples && samples.count) {
                JMXAudioBuffer *buffer = [samples objectAtIndex:sampleIndex%samples.count];
                OSAtomicIncrement64Barrier(&sampleIndex);
                return buffer;
            }
        }
    } else if (sampleIndex != -1) {
        OSAtomicCompareAndSwap64Barrier(sampleIndex, -1, &sampleIndex);
    }
    return nil;
}

#pragma mark -

- (NSString *)displayName
{
    return [NSString stringWithFormat:@"%@", self.moviePath];
}

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"avi", @"mov", @"mp4", @"pdf", @"html", @"png", @"jpg", @"mpg", nil];
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
    if ([aPin.label isEqualTo:@"repeat"]) {
        return [NSNumber numberWithBool:self.repeat];
    } else if ([aPin.label isEqualTo:@"paused"]) {
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
            [self setMoviePath:[NSString stringWithUTF8String:*value]];
    }
}

static v8::Handle<Value>Open(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [entity setMoviePath:[NSString stringWithUTF8String:*value]];
    return v8::Boolean::New(entity.active);
}

static v8::Handle<Value>Close(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    [entity close];
    return v8::Undefined();
}

static v8::Handle<Value>SeekTime(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    [entity seekTime:args[0]->ToNumber()->NumberValue() * 1e9];
    return Undefined();
}

static v8::Handle<Value>SeekAbsoluteTime(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    [entity seekAbsoluteTime:arg->ToNumber()->NumberValue() * 1e9];
    return Undefined();
}

static v8::Handle<Value>SeekFrame(const Arguments& args)
{
    HandleScope handleScope;
    JMXQtMovieEntity *entity = (JMXQtMovieEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    [entity seekFrame:arg->ToNumber()->NumberValue()];
    return Undefined();
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
        Class<JMXFileRead> objcClass = (Class)External::Cast(*(args.Holder()->Get(String::NewSymbol("_objcClass"))))->Value();
        supportedTypes = [objcClass supportedFileTypes];
    }
    v8::Handle<Array> list = v8::Array::New((int)[supportedTypes count]);
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
    classProto->Set("seekTime", FunctionTemplate::New(SeekTime));
    classProto->Set("seekAbsoluteTime", FunctionTemplate::New(SeekAbsoluteTime));
    classProto->Set("seekFrame", FunctionTemplate::New(SeekFrame));
    classProto->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
    
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("duration"), GetDoubleProperty);
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("sampleCount"), GetDoubleProperty);
    return entityTemplate;
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    [super jsRegisterClassMethods:constructor]; // let our super register its methods (if any)
    constructor->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
}
@end
