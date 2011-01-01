//
//  JMXAudioFileEntity.m
//  JMX
//
//  Created by xant on 9/26/10.
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

#import "JMXAudioFile.h"
#import <QuartzCore/QuartzCore.h>
#define __JMXV8__
#import "JMXAudioFileEntity.h"
#import "JMXScript.h"
#import "JMXThreadedEntity.h"

JMXV8_EXPORT_ENTITY_CLASS(JMXAudioFileEntity);

@implementation JMXAudioFileEntity

@synthesize repeat, paused;

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"mp3", @"mp2", @"aif", @"aiff", @"wav", @"avi", nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        audioFile = nil;
        outputPin = [self registerOutputPin:@"audio" withType:kJMXAudioPin];
        repeat = YES;
        self.name = @"CoreAudioFile";
        [self registerInputPin:@"repeat" withType:kJMXBooleanPin andSelector:@"doRepeat:"];
        [self registerInputPin:@"paused" withType:kJMXNumberPin andSelector:@"setPaused:"];

        currentSample = nil;
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        if (threadedEntity)
            return threadedEntity;
    }
    return nil;
}

- (void)dealloc
{
    if (currentSample)
        [currentSample release];
    if (audioFile)
        [audioFile release];
    [super dealloc];
}

- (BOOL)open:(NSString *)file
{
    if (file) {
        @synchronized(audioFile) {
            audioFile = [[JMXAudioFile audioFileWithURL:[NSURL fileURLWithPath:file]] retain];
            if (audioFile) {
                self.frequency = [NSNumber numberWithDouble:([audioFile sampleRate]/512.0)];
                NSArray *path = [file componentsSeparatedByString:@"/"];
                self.label = [path lastObject];
                return YES;
            }
        }
    }
    return NO;
}

- (void)close
{
    // TODO - IMPLEMENT
}

- (void)tick:(uint64_t)timeStamp
{
    JMXAudioBuffer *sample = nil;
    if (active && audioFile) {
        sample = [audioFile readSample];
        if ([audioFile currentOffset] >= [audioFile numFrames] - (512*[audioFile numChannels])) {
            [audioFile seekToOffset:0];
            if (repeat) { // loop on the file if we have to
                sample = [audioFile readSample];
            } else {
                self.active = NO;
                return;
            }
        }
    } 
    if (sample)
        [outputPin deliverData:sample fromSender:self];
    else
        [outputPin deliverData:nil fromSender:self];
    [self outputDefaultSignals:timeStamp];
}

- (void)doRepeat:(id)value
{
    self.repeat = (value && [value respondsToSelector:@selector(boolValue)] && [value boolValue])
                ? YES
                : NO;
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

static v8::Handle<Value> open(const Arguments& args)
{
    //Locker lock;
    HandleScope handleScope;
    JMXAudioFileEntity *entity = (JMXAudioFileEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    BOOL ret = [entity open:[NSString stringWithUTF8String:*value]];
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> close(const Arguments& args)
{
    //Locker lock;
    HandleScope handleScope;
    JMXAudioFileEntity *entity = (JMXAudioFileEntity *)args.Holder()->GetPointerFromInternalField(0);
    [entity close];
    return v8::Undefined();
}

static v8::Handle<Value>SupportedFileTypes(const Arguments& args)
{
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *supportedTypes = nil;
    JMXAudioFileEntity *audioFile = (JMXAudioFileEntity *)args.Holder()->GetPointerFromInternalField(1);
    if (audioFile) {
        supportedTypes = [[audioFile class] supportedFileTypes];
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
    //Locker lock;
    v8::Persistent<v8::FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(v8::FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("CoreAudioFile"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    classProto->Set("open", FunctionTemplate::New(open));
    classProto->Set("close", FunctionTemplate::New(close));
    classProto->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("repeat"), GetBoolProperty, SetBoolProperty);
    return objectTemplate;
}

+ (void)jsRegisterClassMethods:(v8::Handle<v8::FunctionTemplate>)constructor
{
    [super jsRegisterClassMethods:constructor]; // let our super register its methods (if any)
    constructor->Set("supportedFileTypes", FunctionTemplate::New(SupportedFileTypes));
}

@end
