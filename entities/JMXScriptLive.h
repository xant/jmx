//
//  JMXScriptLive.h
//  JMX
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMXFileRead.h"
#import "JMXScriptEntity.h"


@interface JMXScriptLive : JMXScriptEntity {
@private
    JMXInputPin *codeInputPin;
    JMXOutputPin *codeOutputPin;
    NSString *history;
}

- (void)execCode:(NSString *)code;

@end
