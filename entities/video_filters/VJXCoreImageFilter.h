//
//  VJXCoreImageFilter.h
//  VeeJay
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"

@interface VJXCoreImageFilter : VJXEntity {
@protected
    VJXInputPin *inFrame;
    VJXInputPin *filterSelector;
    VJXOutputPin *outFrame;
    NSString *filter;
    CIFilter *ciFilter;
    CIImage *currentFrame;
    NSMutableArray *knownFilters;
}
@property (readonly, nonatomic) NSArray *knownFilters;
@property (readwrite, copy) NSString *filter;
- (void)setFilterValue:(id)value userData:(id)userData;
@end

#ifdef __VJXV8__
VJXV8_DECLARE_ENTITY_CONSTRUCTOR(VJXCoreImageFilter);
#endif