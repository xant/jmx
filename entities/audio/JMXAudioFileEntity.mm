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

JMXV8_EXPORT_ENTITY_CLASS(JMXAudioFileEntity);

@implementation JMXAudioFileEntity

@synthesize repeat;

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
        [self registerInputPin:@"repeat" withType:kJMXNumberPin andSelector:@"doRepeat:"];
        currentSample = nil;
    }
    return self;
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
                self.name = [path lastObject];
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
                return [self stop];
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
    repeat = (value && 
              [value respondsToSelector:@selector(boolValue)] && 
              [value boolValue])
    ? YES
    : NO;
}

#pragma mark V8

static v8::Handle<Value> open(const Arguments& args)
{
    //Locker lock;
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXAudioFileEntity *entity = (JMXAudioFileEntity *)wrap->Value();
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    BOOL ret = [entity open:[NSString stringWithUTF8String:*value]];
    return handleScope.Close(v8::Boolean::New(ret));
}

static v8::Handle<Value> close(const Arguments& args)
{
    //Locker lock;
    HandleScope handleScope;
    Local<Object> self = args.Holder();
    Local<External> wrap = Local<External>::Cast(self->GetInternalField(0));
    JMXAudioFileEntity *entity = (JMXAudioFileEntity *)wrap->Value();
    [entity close];
    return v8::Undefined();
}

+ (v8::Persistent<v8::FunctionTemplate>)jsClassTemplate
{
    //Locker lock;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = v8::Persistent<FunctionTemplate>::New(v8::FunctionTemplate::New());
    entityTemplate->Inherit([super jsClassTemplate]);
    entityTemplate->SetClassName(String::New("VideoLayer"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("open", FunctionTemplate::New(open));
    classProto->Set("close", FunctionTemplate::New(close));
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("repeat"), GetBoolProperty, SetBoolProperty);
    return entityTemplate;
}

@end
