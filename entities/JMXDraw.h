//
//  JMXDrawing.h
//  JMX
//
//  Created by xant on 10/28/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXDrawPath.h"
#import "JMXVideoEntity.h"

@interface JMXDraw : JMXVideoEntity {
@private
    JMXDrawPath *drawPath;
}

@end
