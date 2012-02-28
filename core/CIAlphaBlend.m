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

#import <CIAlphaBlend.h>

@implementation CIAlphaBlend
static CIKernel *alphaBlendKernel = nil;
 
- (id)init
{
    if(alphaBlendKernel == nil)
    {
        NSBundle    *bundle = [NSBundle bundleForClass: [self class]];
		
        NSString    *code = [NSString stringWithContentsOfFile:
                             [bundle pathForResource: @"CIAlphaBlend"
                                            ofType: @"cikernel"]
                              encoding:NSASCIIStringEncoding
                              error:NULL];
        NSArray     *kernels = [CIKernel kernelsWithString: code];
 
        alphaBlendKernel = [[kernels objectAtIndex:0] retain];
    }
    return [super init];
}

- (NSDictionary *)customAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
 
        [NSDictionary dictionaryWithObjectsAndKeys:
			[CIImage imageWithColor:[CIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]], kCIAttributeDefault,
			nil], @"inputBackgroundImage",
		nil];
}

- (CIImage *)outputImage
{
    CISampler *src = [CISampler samplerWithImage: inputImage];
 
    return [self apply: alphaBlendKernel, src, inputBackgroundImage, nil];
}

- (CIFilter *)filterWithName:(NSString *)name
{
    return [CIAlphaBlend filterWithName:name];
}

+ (void)initialize
{
    [CIFilter registerFilterName: @"CIAlphaBlendMode"
        constructor:[[[self alloc] init] autorelease]
        classAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
			@"Alpha Blend", kCIAttributeFilterDisplayName,
			[NSArray arrayWithObject:kCICategoryCompositeOperation], kCIAttributeFilterCategories,
		nil]
	];
}

+ (CIFilter *)filterWithName: (NSString *)name
{
    CIFilter  *filter;
 
    filter = [[self alloc] init];
    return [filter autorelease];
}
@end
