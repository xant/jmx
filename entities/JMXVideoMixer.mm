//
//  JMXVideoMixer.m
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
#define __JMXV8__
#import "JMXVideoMixer.h"
#import "JMXVideoEntity.h"
#include "JMXScript.h"

JMXV8_EXPORT_ENTITY_CLASS(JMXVideoMixer);

@implementation JMXVideoMixer

@synthesize outputSize, blendFilter;

- (id) init
{
    self = [super init];
    if (self) {
        blendFilterPin = [self registerInputPin:@"blendFilter"
                                       withType:kJMXStringPin
                                    andSelector:@"setBlendFilter:"
                                  allowedValues:[CIFilter filterNamesInCategory:kCICategoryCompositeOperation]
                                   initialValue:JMX_MIXER_DEFAULT_BLEND_FILTER];
        imageInputPin = [self registerInputPin:@"video" withType:kJMXImagePin];
        ciBlendFilter = [[CIFilter filterWithName:JMX_MIXER_DEFAULT_BLEND_FILTER] retain];
        [imageInputPin allowMultipleConnections:YES];
        [self registerInputPin:@"videoSize" withType:kJMXSizePin andSelector:@"setOutputSize:"];
        imageSizeOutputPin = [self registerOutputPin:@"videoSize" withType:kJMXSizePin];
        [imageSizeOutputPin allowMultipleConnections:YES];
        imageOutputPin = [self registerOutputPin:@"video" withType:kJMXImagePin];
        [imageOutputPin allowMultipleConnections:YES];
        NSSize defaultSize = { JMX_MIXER_DEFAULT_VIDEOSIZE_WIDTH, JMX_MIXER_DEFAULT_VIDEOSIZE_HEIGHT };
        self.outputSize = [JMXSize sizeWithNSSize:defaultSize];
        currentFrame = nil;
    }
    return self;
}

- (void)dealloc
{    
    [super dealloc];
}

- (void)setBlendFilter:(NSString *)blendFilterName
{
    if (!ciBlendFilter || (ciBlendFilter && ![blendFilterName isEqual:[[ciBlendFilter attributes] 
                                                                   objectForKey:@"CIAttributeFilterName"]]))
    {
        @synchronized(self) {
            CIFilter *newBlendFilter = [CIFilter filterWithName:blendFilterName];
            if (newBlendFilter) {
                if (ciBlendFilter)
                    [ciBlendFilter release];
                ciBlendFilter = [newBlendFilter retain];
                [ciBlendFilter setDefaults];
                blendFilter = [newBlendFilter copy];
            }
        }
    }
}

- (void)tick:(uint64_t)timeStamp
{
    @synchronized(self) {
        NSArray *frames = [imageInputPin readProducers];
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        for (id data in frames) {
            //if ([data isKindOfClass:[CIImage class]]) {
                CIImage *frame = (CIImage *)data;
                if (!currentFrame) {
                    currentFrame = frame;
                } else {

                    [ciBlendFilter setValue:frame forKey:@"inputImage"];
                    [ciBlendFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                    currentFrame = [ciBlendFilter valueForKey:@"outputImage"];
                }
            //}
        }
        if (currentFrame)
            [currentFrame retain];
        else // send a black frame
            currentFrame = [[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]] retain];
        [imageOutputPin deliverData:currentFrame fromSender:self];
    }
    [imageSizeOutputPin deliverData:outputSize]; // XXX - do this only when size changes
}

#pragma mark V8

+ (v8::Persistent<FunctionTemplate>)jsClassTemplate
{
    //Locker lock;
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> classTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    classTemplate->Inherit([super jsClassTemplate]);
    classTemplate->SetClassName(String::New("VideoMixer"));
    classTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    classTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("blendFilter"), GetStringProperty, SetStringProperty);
    NSLog(@"JMXVideoMixer ClassTemplate created");
    return classTemplate;
}

@end
