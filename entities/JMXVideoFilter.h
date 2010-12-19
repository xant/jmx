//
//  JMXVideoFilter.h
//  JMX
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"

@interface JMXVideoFilter : JMXEntity {
@protected
    JMXInputPin *inFrame;
    JMXInputPin *filterSelector;
    JMXOutputPin *outFrame;
    NSString *filter;
    NSMutableArray *knownFilters;
    CIImage *currentFrame;
}
@property (readonly, nonatomic) NSArray *knownFilters;
@property (readwrite, copy) NSString *filter;
- (void)setFilterValue:(id)value userData:(id)userData;

@end
