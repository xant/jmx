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
#include "JMXScript.h"
#import "JMXThreadedEntity.h"


JMXV8_EXPORT_NODE_CLASS(JMXVideoMixer);

@implementation JMXVideoMixer

@synthesize blendFilter;

- (id) init
{
    self = [super init];
    if (self) {
        blendFilterPin = [self registerInputPin:@"blendFilter"
                                       withType:kJMXStringPin
                                    andSelector:@"setBlendFilter:"
                                  allowedValues:[CIFilter filterNamesInCategory:kCICategoryCompositeOperation]
                                   initialValue:JMX_MIXER_DEFAULT_BLEND_FILTER];
        ciBlendFilter = [[CIFilter filterWithName:JMX_MIXER_DEFAULT_BLEND_FILTER] retain];
        self.blendFilter = JMX_MIXER_DEFAULT_BLEND_FILTER;
        imageInputPin = [self registerInputPin:@"video" withType:kJMXImagePin];
        [imageInputPin allowMultipleConnections:YES];
        NSSize defaultSize = { JMX_MIXER_DEFAULT_VIDEOSIZE_WIDTH, JMX_MIXER_DEFAULT_VIDEOSIZE_HEIGHT };
        self.size = [JMXSize sizeWithNSSize:defaultSize];
        self.label = @"VideoMixer";
        currentFrame = nil;
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        if (threadedEntity)
            return (JMXVideoMixer *)threadedEntity;
        [self dealloc];
    }
    return nil;
}

- (void)dealloc
{    
    if (blendFilter)
        [blendFilter release];
    if (ciBlendFilter)
        [ciBlendFilter release];
    [super dealloc];
}

- (NSString *)blendFilter
{
    @synchronized(self) {
        return [[blendFilter retain] autorelease];
    }
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
                if (blendFilter)
                    [blendFilter release];
                blendFilter = [blendFilterName copy];
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
                CGRect rect = CGRectMake(0, 0, size.width, size.height);
                if (!currentFrame) {
                    currentFrame = [frame imageByCroppingToRect:rect];
                } else {

                    [ciBlendFilter setValue:frame forKey:@"inputImage"];
                    [ciBlendFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                    currentFrame = [[ciBlendFilter valueForKey:@"outputImage"] imageByCroppingToRect:rect];
                }
            //}
        }
        if (currentFrame)
            [currentFrame retain];
        else // send a black frame
            currentFrame = [[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]] retain];
    }
    [super tick:timeStamp];
}

#pragma mark V8

+ (v8::Persistent<FunctionTemplate>)jsObjectTemplate
{
    //Locker lock;
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> objectTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("VideoMixer"));
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("blendFilter"), GetStringProperty, SetStringProperty);
    NSDebug(@"JMXVideoMixer objectTemplate created");
    return objectTemplate;
}

@end
