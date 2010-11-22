//
//  JMXEntityProducerTableViewDelegate.h
//  JMX
//
//  Created by Igor Sutton on 11/22/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class JMXEntity;
@class JMXInputPin;

@interface JMXEntityProducerTableViewDelegate : NSObject <NSTableViewDelegate, NSTableViewDataSource> {
    JMXEntity *entity;
    NSString *pinName;
    JMXInputPin *pin;
}

@property (nonatomic, assign) JMXEntity *entity;
@property (nonatomic, copy) NSString *pinName;

@end
