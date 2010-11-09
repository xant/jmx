//
//  JMXCoreImageFilter.h
//  JMX
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXEntity.h"

@interface JMXCoreImageFilter : JMXEntity {
@protected
    JMXInputPin *inFrame;
    JMXInputPin *filterSelector;
    JMXOutputPin *outFrame;
    NSString *filter;
    CIFilter *ciFilter;
    CIImage *currentFrame;
    NSMutableArray *knownFilters;
}
@property (readonly, nonatomic) NSArray *knownFilters;
@property (readwrite, copy) NSString *filter;
- (void)setFilterValue:(id)value userData:(id)userData;
@end

#ifdef __JMXV8__
JMXV8_DECLARE_ENTITY_CONSTRUCTOR(JMXCoreImageFilter);
#endif
