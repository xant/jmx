//
//  JMXTextLayer.m
//  JMX
//
//  Created by xant on 10/26/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#define __JMXV8__
#import "JMXTextEntity.h"
#import "JMXThreadedEntity.h"
#import "JMXColor.h"
#import "JMXScript.h"

JMXV8_EXPORT_NODE_CLASS(JMXTextEntity);

@implementation JMXTextEntity

@synthesize font, bgColor, fgColor;
- (id)init
{
    self = [super init];
    if (self) {
        self.frequency = [NSNumber numberWithDouble:25.0];
        [self registerInputPin:@"fontName"
                      withType:kJMXStringPin
                   andSelector:@"setFontWithName:"
                 allowedValues:[[NSFontManager sharedFontManager] availableFonts]
                  initialValue:[[NSFont systemFontOfSize:[NSFont systemFontSize]] fontName]];
        [self registerInputPin:@"inputText" withType:kJMXTextPin andSelector:@"setText:"];
        [self registerInputPin:@"fontSize" withType:kJMXNumberPin andSelector:@"setFontSize:"];
        [self registerInputPin:@"fontColor" withType:kJMXColorPin andSelector:@"setFontColor:"];
        [self registerInputPin:@"backgroundColor" withType:kJMXColorPin andSelector:@"setBackgroundColor:"];
        attributes = [[NSMutableDictionary dictionary] retain];
        self.font = [NSFont systemFontOfSize:[NSFont systemFontSize]];
        self.fgColor = [NSColor whiteColor];
        self.bgColor = [NSColor blackColor];
        self.text = @"";
        self.label = @"TextEntity";
        [attributes
         setObject:font
         forKey:NSFontAttributeName
         ];
        [attributes
         setObject:fgColor
         forKey:NSForegroundColorAttributeName
         ];
        [attributes
         setObject:bgColor
         forKey:NSBackgroundColorAttributeName
         ];
        renderer = [[JMXTextRenderer alloc] init];
        renderedText = nil;
        JMXThreadedEntity *threadedEntity = [JMXThreadedEntity threadedEntity:self];
        if (threadedEntity)
            return threadedEntity;
        [self dealloc];
    }
    return nil;
}

- (void)dealloc
{
    [renderer release];
    [attributes release];
    if (renderedText)
        [renderedText release];
    [super dealloc];
}

- (void)renderText
{
    //if (needsNewFrame) {
    stanStringAttrib = attributes;
    CVPixelBufferRef textFrame;
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       [NSNumber numberWithInt:size.width], kCVPixelBufferWidthKey,
                       [NSNumber numberWithInt:size.height], kCVPixelBufferHeightKey,
                       [NSNumber numberWithInt:size.width*4],kCVPixelBufferBytesPerRowAlignmentKey,
                       [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey, 
                       [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, 
                       [NSNumber numberWithBool:YES], kCVPixelBufferOpenGLCompatibilityKey,
                       nil];
    
    // create pixel buffer
    CVReturn ret = CVPixelBufferCreate(kCFAllocatorDefault,
                                       size.width,
                                       size.height,
                                       k32ARGBPixelFormat,
                                       (CFDictionaryRef)d,
                                       &textFrame);
    if (ret == noErr) {
        // TODO - Implement properly
        //NSFont * font =[NSFont fontWithName:@"Helvetica" size:32.0];
        [renderer initWithString:text withAttributes:stanStringAttrib];
        [renderer drawOnBuffer:textFrame];
        @synchronized(self) {
            if (renderedText)
                [renderedText release];
            renderedText = [[CIImage imageWithCVImageBuffer:textFrame] retain];
        }
        CVPixelBufferRelease(textFrame);
        needsNewFrame = NO;
    } else {
        // TODO - Error Messages
    }
    //}
}

- (void)setSize:(JMXSize *)theSize
{
    [super setSize:theSize];
    [self renderText];
}

- (void)setBackgroundColor:(NSColor *)color
{
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSBackgroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setBackgroundColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)transparency
{
    NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:transparency];
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSBackgroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontColor:(NSColor *)color
{
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSForegroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)transparency
{
    NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:transparency];
    if (color) {
        @synchronized(self) {
            [attributes setObject:color forKey:NSForegroundColorAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontSize:(NSNumber *)fontSize
{
    NSFont *newFont = [NSFont fontWithName:[self.font fontName] size:[fontSize floatValue]];
    if (newFont) {
        self.font = newFont;
        @synchronized(self) {
            [attributes setObject:newFont forKey:NSFontAttributeName];
        }
        [self renderText];
    }
}

- (void)setFontWithName:(NSString *)fontName
{
    NSFont *newFont = [NSFont fontWithName:fontName size:[self.font pointSize]];
    if (newFont) {
        self.font = newFont;
        @synchronized(self) {
            [attributes setObject:newFont forKey:NSFontAttributeName];
        }
        [self renderText];
    }
}

- (void)setText:(NSString *)newText
{
    if (text)
        [text release];
    text = [newText retain];
    [self renderText];
}

- (void)tick:(uint64_t)timeStamp
{
    if (renderedText) {
        if (currentFrame)
            [currentFrame release];
        currentFrame = [renderedText retain];
    }
    [super tick:timeStamp];
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
            [self setText:[NSString stringWithUTF8String:*value]];
    }
}

static v8::Handle<Value>SetText(const Arguments& args)
{
    HandleScope handleScope;
    JMXTextEntity *entity = (JMXTextEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [entity setText:[NSString stringWithUTF8String:*value]];
    return handleScope.Close(Undefined());
}

static v8::Handle<Value>SetFont(const Arguments& args)
{
    HandleScope handleScope;
    JMXTextEntity *entity = (JMXTextEntity *)args.Holder()->GetPointerFromInternalField(0);
    v8::Handle<Value> arg = args[0];
    v8::String::Utf8Value value(arg);
    [entity setFontWithName:[NSString stringWithUTF8String:*value]];
    return handleScope.Close(Undefined());    
}

static v8::Handle<Value>SetBackgroundColor(const Arguments& args)
{
    BOOL ret = NO;
    HandleScope handleScope;
    JMXTextEntity *entity = (JMXTextEntity *)args.Holder()->GetPointerFromInternalField(0);
    String::Utf8Value str(args[0]->ToString());
    if (strcmp(*str, "[object Color]") == 0) {
        v8::Handle<Object> object = args[0]->ToObject();
        JMXColor *color = (JMXColor *)object->GetPointerFromInternalField(0);
        [entity setBackgroundColor:color];
        ret = YES;
    }
    return v8::Boolean::New(ret);

}

static v8::Handle<Value>SetFontColor(const Arguments& args)
{
    HandleScope handleScope;
    JMXTextEntity *entity = (JMXTextEntity *)args.Holder()->GetPointerFromInternalField(0);
    String::Utf8Value str(args[0]->ToString());
    if (strcmp(*str, "[object Color]") == 0) {
        v8::Handle<Object> object = args[0]->ToObject();
        JMXColor *color = (JMXColor *)object->GetPointerFromInternalField(0);
        [entity setFontColor:color];
    }
    return handleScope.Close(Undefined());
}

+ (v8::Persistent<v8::FunctionTemplate>)jsObjectTemplate
{
    HandleScope handleScope;
    v8::Persistent<v8::FunctionTemplate> entityTemplate = [super jsObjectTemplate];
    entityTemplate->SetClassName(String::New("TextRenderer"));
    entityTemplate->InstanceTemplate()->SetInternalFieldCount(1);
    v8::Handle<ObjectTemplate> classProto = entityTemplate->PrototypeTemplate();
    classProto->Set("setText", FunctionTemplate::New(SetText));
    classProto->Set("setFont", FunctionTemplate::New(SetFont));
    classProto->Set("setFontColor", FunctionTemplate::New(SetFontColor));
    classProto->Set("setBackgroundColor", FunctionTemplate::New(SetBackgroundColor));
    return entityTemplate;
}
@end
