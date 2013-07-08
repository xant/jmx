//
//  JMXImageEntity.m
//  JMX
//
//  Created by Igor Sutton on 8/25/10.
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

#define __JMXV8__
#import "JMXImageEntity.h"
#import <QTKit/QTKit.h>
#import "JMXThreadedEntity.h"
#import "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXImageEntity);

@implementation JMXImageEntity

@synthesize imagePath, image, needsRender;

+ (NSArray *)supportedFileTypes
{
    // TODO - find a better way to return supported image types
    return [NSArray arrayWithObjects:@"jpg", @"tiff", @"pdf", @"png", @"gif", @"bmp", nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object change:(NSDictionary *)change
                       context:(void *)context
{
    
    self.needsRender = YES;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.image = nil;
        JMXThreadedEntity *threadedEntity = [[JMXThreadedEntity threadedEntity:self] retain];
        if (threadedEntity) {
            //self.frequency = [NSNumber numberWithDouble:0.5]; // override frequency
            [self addObserver:self
                   forKeyPath:@"alpha"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"brightness"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"contrast"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"rotation"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"scaleRatio"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"origin"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"size"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            [self addObserver:self
                   forKeyPath:@"tileFrame"
                      options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld)
                      context:nil];
            return (JMXImageEntity *)threadedEntity;
        }
        [self dealloc];
    }
    return nil;
}

- (BOOL)open:(NSString *)file
{
    if (file) {
        @synchronized(self) {
            self.imagePath = file;
            NSData *imageData = [[NSData alloc] initWithContentsOfFile:self.imagePath];
            if (imageData) {
                self.image = [CIImage imageWithData:imageData];
                NSArray *path = [file componentsSeparatedByString:@"/"];
                self.label = [path lastObject];
                self.size = [JMXSize sizeWithNSSize:NSSizeFromCGSize(self.image.extent.size)];
                self.needsRender = YES;
                return YES;
            }
        }
    }
    return NO;
}

- (void)close
{
    if (self.imagePath)
        [self.imagePath release];
    self.imagePath = nil;
    if (self.image)
        self.image = nil;
}

- (void)tick:(uint64_t)timeStamp
{
    if (self.image && self.needsRender) {
        @synchronized(self) {
            CIImage *frame = self.image;
            CGRect imageRect = [frame extent];
            // scale the image to fit the layer size, if necessary
            if (size.width != imageRect.size.width || size.height != imageRect.size.height)
            {
                CIFilter *scaleFilter = [CIFilter filterWithName:@"CIAffineTransform"];
                float xScale = size.width / imageRect.size.width;
                float yScale = size.height / imageRect.size.height;
                // TODO - take scaleRatio into account for further scaling requested by the user
                NSAffineTransform *transform = [NSAffineTransform transform];
                [transform scaleXBy:xScale yBy:yScale];
                [scaleFilter setDefaults];
                [scaleFilter setValue:transform forKey:@"inputTransform"];
                [scaleFilter setValue:frame forKey:@"inputImage"];
                frame = [scaleFilter valueForKey:@"outputImage"];
            }
            if (currentFrame)
                [currentFrame release];
            currentFrame = [frame retain];
            self.needsRender = NO;
        }
    }
    [super tick:timeStamp];
}

- (void)dealloc
{
    [self removeObserver:self
              forKeyPath:@"alpha"];
    [self removeObserver:self
              forKeyPath:@"brightness"];
    [self removeObserver:self
              forKeyPath:@"contrast"];
    [self removeObserver:self
              forKeyPath:@"rotation"];
    [self removeObserver:self
              forKeyPath:@"scaleRatio"];
    [self removeObserver:self
              forKeyPath:@"origin"];
    [self removeObserver:self
              forKeyPath:@"size"];
    [self removeObserver:self
              forKeyPath:@"tileFrame"];
    [super dealloc];
}
#pragma mark -

- (NSString *)displayName
{
    return [NSString stringWithFormat:@"%@", self.imagePath];
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
    JMXImageEntity *entity = (JMXImageEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [entity open:[NSString stringWithUTF8String:*value]];
    return v8::Boolean::New(entity.active);
}

static v8::Handle<Value>Close(const Arguments& args)
{
    HandleScope handleScope;
    JMXImageEntity *entity = (JMXImageEntity *)args.Holder()->GetPointerFromInternalField(0);
    [entity close];
    return v8::Undefined();
}

static v8::Handle<Value>SupportedFileTypes(const Arguments& args)
{
    HandleScope handleScope;
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSArray *supportedTypes = nil;
    JMXImageEntity *imageFile = (JMXImageEntity *)args.Holder()->GetPointerFromInternalField(1);
    if (imageFile) {
        supportedTypes = [[imageFile class] supportedFileTypes];
    } else {
        Class<JMXFileRead> objcClass = (Class)External::Cast(*(args.Holder()->Get(String::NewSymbol("_objcClass"))))->Value();
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
    entityTemplate->SetClassName(String::New("ImageFile"));
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
