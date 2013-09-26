//
//  JMXApplication.h
//  JMX
//
//  Created by xant on 7/11/13.
//  Copyright (c) 2013 Dyne.org. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JMXApplicationDelegate.h"

@interface JMXApplication : NSObject <JMXApplicationDelegate>
{
    NSMutableArray *argv;
}

@property (nonatomic, readonly) BOOL batchMode;
@property (nonatomic, copy) NSString *appName;

@end

