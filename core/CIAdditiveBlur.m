/*  JMX
 *  (c) Copyright 2009 Andrea Guzzo <xant@dyne.org>
 *
 * This source code is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Public License as published 
 * by the Free Software Foundation; either version 3 of the License,
 * or (at your option) any later version.
 *
 * This source code is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * Please refer to the GNU Public License for more details.
 *
 * You should have received a copy of the GNU Public License along with
 * this source code; if not, write to:
 * Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 */

#import <CIAdditiveBlur.h>

#define kCIAdditiveBlurMaxHistory 60

@implementation CIAdditiveBlur
static CIKernel *additiveBlurKernel = nil;
 
- (id)init
{
    self = [super init];
    if (self) {
        if(additiveBlurKernel == nil)
        {
            NSBundle    *bundle = [NSBundle bundleForClass: [self class]];
            
            NSString    *code = [NSString stringWithContentsOfFile:
                                 [bundle pathForResource: @"CIAdditiveBlur"
                                                ofType: @"cikernel"]
                                  encoding:NSASCIIStringEncoding
                                  error:NULL];
            NSArray     *kernels = [CIKernel kernelsWithString: code];
     
            additiveBlurKernel = [[kernels objectAtIndex:0] retain];
        }
        history = [[NSMutableArray alloc] initWithCapacity:kCIAdditiveBlurMaxHistory];
    }
    return self;
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [NSDictionary dictionaryWithObjectsAndKeys:
         [NSNumber numberWithDouble:  0.0], kCIAttributeMin,
         [NSNumber numberWithDouble:  1.0], kCIAttributeMax,
         [NSNumber numberWithDouble:  0.0], kCIAttributeSliderMin,
         [NSNumber numberWithDouble:  1.0], kCIAttributeSliderMax,
         [NSNumber numberWithDouble:  0.5], kCIAttributeDefault,
         [NSNumber numberWithDouble:  0.0], kCIAttributeIdentity,
         kCIAttributeTypeScalar,            kCIAttributeType,
         nil], @"inputOpacity",
		nil];
}

- (CIImage *)outputImage
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    CIImage *image = nil;
    // rebuild last visible frame from the history
    for (CIImage *background in history) {
        if (!image) {
            image = background;
        } else {
            image = [self apply: additiveBlurKernel, background, image, inputOpacity, nil];
        }
    }
    if (!image) // if we don't have any history let's just get the current frame
        image = inputImage;

    // apply the current frame on top of the background
    image = [self apply: additiveBlurKernel, inputImage, image, inputOpacity, nil];

    // keep the history
    int inputHistoryLength = [inputOpacity floatValue] * kCIAdditiveBlurMaxHistory;   
    while (history.count > inputHistoryLength)
        [history removeObjectAtIndex:0];
    [history addObject:inputImage];
    
    [image retain];
    [pool release];
    return [image autorelease];
}

- (CIFilter *)filterWithName:(NSString *)name
{
    return [CIAdditiveBlur filterWithName:name];
}

+ (void)initialize
{
    [CIFilter registerFilterName: @"CIAdditiveBlur"
        constructor:[[[self alloc] init] autorelease]
                 classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                   @"Delayed alpha blit", kCIAttributeFilterDisplayName,
                                   [NSArray arrayWithObject:kCICategoryBlur], kCIAttributeFilterCategories,
		nil]
	];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
 
    filter = [[self alloc] init];
    return [filter autorelease];
}

- (void)dealloc
{
    [inputImage release];
    inputImage = nil;
    [history release];
    [inputOpacity release];
    inputOpacity = nil;
    [super dealloc];
}
@end
