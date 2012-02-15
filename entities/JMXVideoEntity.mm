//
//  JMXVideoEntity.m
//  JMX
//
//  Created by Igor Sutton on 8/24/10.
//  Copyright 2010 StrayDev.com. All rights reserved.
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

#import "CIAlphaFade.h"
#define __JMXV8__ 1
#import "JMXVideoEntity.h"
#import <QuartzCore/QuartzCore.h>
#import "JMXScript.h"

@implementation JMXVideoEntity

@synthesize alpha, saturation, brightness, contrast, rotation,
            origin, size, scaleRatio, fps, tileFrame;

- (id)init
{
    self = [super init];
    if (self) {
        currentFrame = nil;
        self.label = @"VideoEntity";
        colorFilter = [[CIFilter filterWithName:@"CIColorControls"] retain];
        [colorFilter setDefaults];
        alphaFilter = [[CIFilter filterWithName:@"CIAlphaFade"] retain];
        [alphaFilter setDefaults]; // XXX - setDefaults doesn't work properly
        NSDictionary *filterAttributes = [colorFilter attributes];
        NSSize defaultLayerSize = { 640, 480 };
        self.fps = [NSNumber numberWithDouble:25.0];
        self.size = [JMXSize sizeWithNSSize:defaultLayerSize];
        self.saturation = [colorFilter valueForKey:@"inputSaturation"];
        self.brightness = [colorFilter valueForKey:@"inputBrightness"];
        self.contrast = [colorFilter valueForKey:@"inputContrast"];
        self.alpha = [NSNumber numberWithFloat:1.0];
        self.rotation = [NSNumber numberWithFloat:0.0];
        self.scaleRatio = [NSNumber numberWithFloat:1.0];
        NSPoint zeroPoint = { 0, 0 };
        self.origin = [JMXPoint pointWithNSPoint:zeroPoint];
        JMXInputPin *inputPin;
        inputPin = [self registerInputPin:@"alpha"
                                 withType:kJMXNumberPin
                              andSelector:@"setAlpha:"
                            allowedValues:nil
                            initialValue:self.alpha];
        [inputPin setMinLimit:[NSNumber numberWithFloat:0.0]];
        [inputPin setMaxLimit:[NSNumber numberWithFloat:2.0]];
        inputPin = [self registerInputPin:@"saturation"
                                  withType:kJMXNumberPin
                               andSelector:@"setSaturation:"
                             allowedValues:nil
                             initialValue:self.saturation];
        [inputPin setMinLimit:[[filterAttributes objectForKey:@"inputSaturation"] objectForKey:@"CIAttributeSliderMin"]];
        [inputPin setMaxLimit:[[filterAttributes objectForKey:@"inputSaturation"] objectForKey:@"CIAttributeSliderMax"]];
        inputPin = [self registerInputPin:@"brightness"
                                 withType:kJMXNumberPin
                              andSelector:@"setBrightness:"
                            allowedValues:nil
                            initialValue:self.brightness];
        [inputPin setMinLimit:[[filterAttributes objectForKey:@"inputBrightness"] objectForKey:@"CIAttributeSliderMin"]];
        [inputPin setMaxLimit:[[filterAttributes objectForKey:@"inputBrightness"] objectForKey:@"CIAttributeSliderMax"]];
        inputPin = [self registerInputPin:@"contrast" 
                                 withType:kJMXNumberPin
                              andSelector:@"setContrast:"
                            allowedValues:nil
                             initialValue:self.contrast];
        [inputPin setMinLimit:[[filterAttributes objectForKey:@"inputContrast"] objectForKey:@"CIAttributeSliderMin"]];
        [inputPin setMaxLimit:[[filterAttributes objectForKey:@"inputContrast"] objectForKey:@"CIAttributeSliderMax"]];
        inputPin = [self registerInputPin:@"rotation"
                                 withType:kJMXNumberPin
                              andSelector:@"setRotation:"
                            allowedValues:nil
                             initialValue:self.rotation];
        [inputPin setMinLimit:[NSNumber numberWithFloat:0.0]];
        [inputPin setMaxLimit:[NSNumber numberWithFloat:360.0]];
        inputPin = [self registerInputPin:@"scaleRatio"
                                 withType:kJMXNumberPin
                              andSelector:@"setScaleRatio:"
                            allowedValues:nil
                             initialValue:[NSNumber numberWithFloat:1.0]];
        [inputPin setMinLimit:[NSNumber numberWithFloat:0.0]];
        [inputPin setMaxLimit:[NSNumber numberWithFloat:5.0]];
        [self registerInputPin:@"origin"
                      withType:kJMXPointPin
                   andSelector:@"setOrigin:"
                 allowedValues:nil
                  initialValue:self.origin];
        
        [self registerInputPin:@"originX"
                      withType:kJMXNumberPin
                   andSelector:@"setOriginX:"
                 allowedValues:nil
                  initialValue:[NSNumber numberWithDouble:self.origin.x]];
        
        [self registerInputPin:@"originY"
                      withType:kJMXNumberPin
                   andSelector:@"setOriginY:"
                 allowedValues:nil
                  initialValue:[NSNumber numberWithDouble:self.origin.y]];
        
        [self registerInputPin:@"frameSize"
                      withType:kJMXSizePin
                   andSelector:@"setSize:"
                 allowedValues:nil
                  initialValue:self.size];
        
        tileFrame = NO;
        [self registerInputPin:@"tileFrame"
                      withType:kJMXBooleanPin
                   andSelector:@"setTileFrame:"
                 allowedValues:nil initialValue:[NSNumber numberWithBool:tileFrame]];

        fpsPin = [self registerInputPin:@"fps" withType:kJMXNumberPin andSelector:@"setFps:"];
        [fpsPin setMinLimit:[NSNumber numberWithDouble:1.0]];
        [fpsPin setMaxLimit:[NSNumber numberWithDouble:90.0]];
        fpsPin.data = self.fps;
        // we output at least 1 image
        outputFramePin = [self registerOutputPin:@"frame" withType:kJMXImagePin];
        outputFrameSizePin = [self registerOutputPin:@"frameSize" withType:kJMXSizePin];
        [outputFrameSizePin setContinuous:NO];
        [outputFrameSizePin allowMultipleConnections:YES];
    }
    return self;
}

- (void)setOriginX:(NSNumber *)x
{
    self.origin.x = [x doubleValue];
}


- (void)setOriginY:(NSNumber *)y
{
    self.origin.y = [y doubleValue];
}

- (void)dealloc
{
    if (currentFrame)
        [currentFrame release];
    if (colorFilter)
        [colorFilter release];
    if (alphaFilter)
        [alphaFilter release];
    self.size = nil;
    [super dealloc];
}

- (void)tick:(uint64_t)timeStamp
{
    CIImage *outputFrame = self.currentFrame;
    if (outputFrame) {
        // Apply image parameters
        // ensure using accessors (by calling self.property) since they will take care of locking
        [colorFilter setValue:self.saturation forKey:@"inputSaturation"];
        [colorFilter setValue:self.brightness forKey:@"inputBrightness"];
        [colorFilter setValue:self.contrast forKey:@"inputContrast"];
        [colorFilter setValue:outputFrame forKey:@"inputImage"];
        // scale the image to fit the configured layer size
        CIImage *frame = [colorFilter valueForKey:@"outputImage"];
       
        // frame should be produced with the correct size already by the layer implementation
        // but if the user requested a size impossible to be produced by the source, 
        // we scale it here to honor user request for a specific size
        BOOL applyTransforms = NO;
        // and apply affine transforms if necessary (scale, rotation and displace
        CIFilter *transformFilter = [CIFilter filterWithName:@"CIAffineTransform"];
        NSAffineTransform *transform = [NSAffineTransform transform];
        CGRect imageRect = [frame extent];
        if (size.width != imageRect.size.width || size.height != imageRect.size.height) {
            applyTransforms = YES;
            float xScale = size.width / imageRect.size.width;
            float yScale = size.height / imageRect.size.height;
            if (xScale && yScale)
                [transform scaleXBy:xScale * scaleRatio.floatValue yBy:yScale * scaleRatio.floatValue];
        } else if (scaleRatio.floatValue != 1.0) {
            applyTransforms = YES;
            [transform scaleXBy:scaleRatio.floatValue yBy:scaleRatio.floatValue];
        }
        if ([rotation floatValue]) {
            applyTransforms = YES;
            NSAffineTransform *rotoTransform = [NSAffineTransform transform];
            [rotoTransform rotateByDegrees:[rotation floatValue]];
            CGFloat deg = ([rotation floatValue]*M_PI)/180.0;
            CGFloat x, y;
            x = ((size.width)-((size.width)*cos(deg)-(size.height)*sin(deg)))/2;
            y = ((size.height)-((size.width)*sin(deg)+(size.height)*cos(deg)))/2;
            NSAffineTransform *rotoTranslate = [NSAffineTransform transform];
            [rotoTranslate translateXBy:x yBy:y];
            [rotoTransform appendTransform:rotoTranslate];
            [transform appendTransform:rotoTransform];
        }
        [transformFilter setDefaults];
        [transformFilter setValue:transform forKey:@"inputTransform"];
        [transformFilter setValue:frame forKey:@"inputImage"];
        if (origin.x || origin.y) {
            applyTransforms = YES;
            NSAffineTransform *originTransform = [NSAffineTransform transform];
            CGRect rect = [outputFrame extent];
            CGFloat x = fmod(origin.x, rect.size.width);
            CGFloat y = fmod(origin.y, rect.size.height);

            [originTransform translateXBy:x yBy:y];
            [transform appendTransform:originTransform];
            CIFilter *originFilter = transformFilter;
            if (tileFrame)
            {
                CIImage *firstFrame = [transformFilter valueForKey:@"outputImage"];
               
                NSAffineTransform *loopTransform = [NSAffineTransform transform];
                [loopTransform translateXBy:(x > 0 ? -size.width : size.width) yBy:y];
                [transform appendTransform:loopTransform];
                [transformFilter setValue:frame forKey:@"inputImage"];
                
                CIImage *secondFrame = [transformFilter valueForKey:@"outputImage"];
                
                CIFilter *blendFilter = [CIFilter filterWithName:@"CIScreenBlendMode"];
                [blendFilter setDefaults];
                [blendFilter setValue:firstFrame forKey:@"inputImage"];
                [blendFilter setValue:secondFrame forKey:@"inputBackgroundImage"];
                originFilter = blendFilter;
            }
            frame = [originFilter valueForKey:@"outputImage"];
        } else if (applyTransforms) {
            frame = [transformFilter valueForKey:@"outputImage"];
        }
        
        if (frame) {
            // apply alpha
            [alphaFilter setValue:alpha forKey:@"outputOpacity"];
            [alphaFilter setValue:frame forKey:@"inputImage"];
            frame = [alphaFilter valueForKey:@"outputImage"];
            outputFrame = frame;
        }
        // TODO - compute the effective fps and send it to an output pin 
        //        for debugging purposes
    }
    [outputFramePin deliverData:outputFrame fromSender:self];
    if (![outputFrameSizePin.data isEqualTo:size])
        [outputFrameSizePin deliverData:size];
}

- (CIImage *)currentFrame
{   
    @synchronized(self) {
        if (currentFrame) {
            CIImage *frame = [currentFrame retain];
            return [frame autorelease];
        }
    }
    return nil;
}


#pragma mark V8
using namespace v8;
static v8::Persistent<v8::FunctionTemplate> objectTemplate;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    NSDebug(@"JMXVideoEntity objectTemplate created");
    v8::Persistent<v8::FunctionTemplate> objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    // accessors to image parameters
    objectTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("saturation"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("brightness"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("contrast"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("alpha"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("rotation"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("scaleRatio"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("fps"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("saturation"), GetNumberProperty, SetNumberProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("size"), GetSizeProperty, SetSizeProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("origin"), GetPointProperty, SetPointProperty);
    objectTemplate->InstanceTemplate()->SetAccessor(String::NewSymbol("tileFrame"), GetBoolProperty, SetBoolProperty);

    return objectTemplate;
}

@end
