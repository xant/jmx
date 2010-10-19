//
//  VJXVideoFilter.h
//  VeeJay
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "VJXEntity.h"

@interface VJXVideoFilter : VJXEntity {
@protected
    VJXInputPin *inFrame;
    VJXInputPin *filterSelector;
    VJXOutputPin *outFrame;
    CIFilter *filter;
    CIImage *currentFrame;
    NSMutableArray *knownFilters;
}

@end
