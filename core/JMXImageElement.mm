//
//  JMXImageElement.mm
//  JMX
//
//  Created by xant on 1/18/11.
//  Copyright 2011 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXImageElement.h"
#import "JMXScript.h"
#import "JMXAttribute.h"

JMXV8_EXPORT_CLASS(JMXImageElement)

@implementation JMXImageElement

@synthesize alt, src, useMap, isMap, width, height,
            naturalWidth, naturalHeight, complete, imageData;

- (id)init
{
    self = [super init];
    if (self) {
        [self addAttribute:[JMXAttribute attributeWithName:@"alt" stringValue:@""]];
        [self addAttribute:[JMXAttribute attributeWithName:@"src" stringValue:@""]];
        [self addAttribute:[JMXAttribute attributeWithName:@"useMap" stringValue:@""]];
        [self addAttribute:[JMXAttribute attributeWithName:@"isMap" stringValue:@"0"]];
        [self addAttribute:[JMXAttribute attributeWithName:@"width" stringValue:@"0"]];
        [self addAttribute:[JMXAttribute attributeWithName:@"height" stringValue:@"0"]];
        [self addAttribute:[JMXAttribute attributeWithName:@"naturalWidth" stringValue:@"0"]];
        [self addAttribute:[JMXAttribute attributeWithName:@"naturalHeight" stringValue:@"0"]];
        [self addAttribute:[JMXAttribute attributeWithName:@"complete" stringValue:@"0"]];
    }
    return self;
}

- (NSString *)alt
{
    @synchronized(self) {
        return alt;
    }
}

- (void)setAlt:(NSString *)newValue
{
    @synchronized(self) {
        if (alt)
            [alt release];
        alt = [newValue copy];
        NSXMLNode *attr = [self attributeForName:@"alt"];
        if (attr)
            [attr setStringValue:alt];
    }
}

- (void)loadImageData
{
    [imageLock lock];
    if (imageData)
        [imageData release];
    imageData = [[NSData dataWithContentsOfURL:[NSURL URLWithString:src]] retain];
    [imageLock unlock];
}

- (NSString *)src
{
    @synchronized(self) {
        return src;
    }
}

- (void)setSrc:(NSString *)newValue
{
    @synchronized(self) {
        if (src) {
            if ([src isEqualTo:newValue]) // same value has been provided
                return; // we don't need to do anything
            // let's release the old value if instead a new one has
            // been provided
            [src release]; 
        }
        src = [newValue copy];
        NSXMLNode *attr = [self attributeForName:@"src"];
        if (attr)
            [attr setStringValue:src];
    }
    [self loadImageData];
}

- (NSUInteger)width
{
    @synchronized(self) {
        return width;
    }
}

- (void)setWidth:(NSUInteger)newValue
{
    @synchronized(self) {
        width = newValue;
        NSXMLNode *attr = [self attributeForName:@"width"];
        if (attr)
            [attr setStringValue:[NSString stringWithFormat:@"%lu", newValue]];
    }
}

- (NSUInteger)height
{
    @synchronized(self) {
        return height;
    }
}

- (void)setHeight:(NSUInteger)newValue
{
    @synchronized(self) {
        height = newValue;
        NSXMLNode *attr = [self attributeForName:@"height"];
        if (attr)
            [attr setStringValue:[NSString stringWithFormat:@"%lu", newValue]];
    }
}

- (CGImageRef)cgImage
{
    [imageLock lock];
    NSBitmapImageRep *rep = [NSBitmapImageRep imageRepWithData:imageData];
    [imageLock unlock];
    return rep.CGImage;
}

- (CIImage *)ciImage
{
    [imageLock lock];
    CIImage *ciImage = [CIImage imageWithData:imageData];
    [imageLock unlock];
    return ciImage; // NOTE - this is autoreleased
}

- (NSImage *)nsImage
{
    // TODO - IMPLEMENT
    return nil;
}
#pragma mark V8

using namespace v8;

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    //v8::Locker lock;
    if (!objectTemplate.IsEmpty())
        return objectTemplate;
    objectTemplate = v8::Persistent<FunctionTemplate>::New(FunctionTemplate::New());
    objectTemplate->Inherit([super jsObjectTemplate]);
    objectTemplate->SetClassName(String::New("Image"));
    v8::Handle<ObjectTemplate> classProto = objectTemplate->PrototypeTemplate();
    
    v8::Handle<ObjectTemplate> instanceTemplate = objectTemplate->InstanceTemplate();
    instanceTemplate->SetInternalFieldCount(1);
    
    // Add accessors for each of the fields of the entity.
    instanceTemplate->SetAccessor(String::NewSymbol("alt"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("src"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("useMap"), GetStringProperty, SetStringProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("isMap"), GetBoolProperty, SetBoolProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("width"), GetIntProperty, SetIntProperty);
    instanceTemplate->SetAccessor(String::NewSymbol("height"), GetIntProperty, SetIntProperty);

    
    NSDebug(@"JMXImageElement objectTemplate created");
    return objectTemplate;
}

@end
