//
//  JMXCoreImageFilter.h
//  JMX
//
//  Created by xant on 10/19/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXVideoFilter.h"

@interface JMXCoreImageFilter : JMXVideoFilter {
@protected
    CIFilter *ciFilter;
}
@end

#ifdef __JMXV8__
JMXV8_DECLARE_ENTITY_CONSTRUCTOR(JMXCoreImageFilter);
#endif