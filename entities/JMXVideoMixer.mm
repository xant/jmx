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
                blendFilter = [newBlendFilter copy];
            }
        }
    }
}

- (void)tick:(uint64_t)timeStamp
{
    NSArray *frames = [imageInputPin readProducers];
    @synchronized(self) {
        if (currentFrame) {
            [currentFrame release];
            currentFrame = nil;
        }
        for (CIImage *frame in frames) {
#if 0
            if ([producer isKindOfClass:[JMXLayer class]]) {
                JMXLayer *layer = (JMXLayer *)producer;
                if (layer.size.width != outputSize.width || layer.size.height != outputSize.height)
                {
                    CIFilter *filter = [CIFilter filterWithName:@"CIAffineTransform"];
                    CGRect imageRect = [frame extent];
                    float xScale = outputSize.width / imageRect.size.width;
                    float yScale = outputSize.height / imageRect.size.height;
                    NSAffineTransform *transform = [NSAffineTransform transform];
                    [transform scaleXBy:xScale yBy:yScale];
                    [filter setDefaults];
                    [filter setValue:transform forKey:@"inputTransform"];
                    [filter setValue:frame forKey:@"inputImage"];
                    frame = [filter valueForKey:@"outputImage"];
                }
            }
#endif
            if (!currentFrame) {
                currentFrame = frame;
            } else {
                /*
                if (!ciBlendFilter)
                    ciBlendFilter = [[CIFilter filterWithName:JMX_MIXER_DEFAULT_BLEND_FILTER] retain];
                 */ 
                [ciBlendFilter setDefaults];
                [ciBlendFilter setValue:frame forKey:@"inputImage"];
                [ciBlendFilter setValue:currentFrame forKey:@"inputBackgroundImage"];
                currentFrame = [ciBlendFilter valueForKey:@"outputImage"];
            }
        }
        if (currentFrame)
            [currentFrame retain];
        else // send a black frame
            currentFrame = [[CIImage imageWithColor:[CIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:1.0]] retain];
        [imageOutputPin deliverData:currentFrame fromSender:self];
        [imageSizeOutputPin deliverData:outputSize];
    }
}


#pragma mark V8

+ (v8::Persistent<FunctionTemplate>)jsClassTemplate
{
    //Locker lock;
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    entityTemplate->Inherit([super jsClassTemplate]);
    entityTemplate->SetClassName(String::New("CoreImageFilter"));
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    //classProto->Set("avaliableFilters", FunctionTemplate::New(AvailableFilters));
    //classProto->Set("selectFilter", FunctionTemplate::New(SelectFilter));
    entityTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("blendFilter"), GetStringProperty, SetStringProperty);
    return entityTemplate;
}

@end
