//
//  VJXSignal.h
//  VeeJay
//
//  Created by xant on 9/12/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface VJXSignal : NSObject {
    id data;
    id sender;
}

@property (retain) id data;
@property (retain) id sender;

+ signalFrom:(id)sender withData:(id)data;

@end
