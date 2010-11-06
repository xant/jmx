//
//  VJXJavascriptFile.m
//  VeeJay
//
//  Created by xant on 11/4/10.
//  Copyright 2010 Dyne.org. All rights reserved.
//

#import "VJXJavascriptFile.h"
#import "VJXJavaScript.h"

@implementation VJXJavascriptFile

+ (NSArray *)supportedFileTypes
{
    return [NSArray arrayWithObjects:@"js", @"javascript", nil];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.frequency = [NSNumber numberWithDouble:1.0];
        path = nil;
        active = NO;
        [self unregisterAllPins]; // no pins for now
    }
    return self;
}

- (BOOL)open:(NSString *)newPath
{
    @synchronized(self) {
        if (path)
            [path release];
        path = [newPath retain];
        self.name = [[path componentsSeparatedByString:@"/"] lastObject];
    }
    return YES;
}

- (void)close
{
}

- (void)tick:(uint64_t)timeStamp
{
    if (path) {
        [VJXJavaScript runScript:[NSString stringWithFormat:@"include('%@');", path] withEntity:self];
        quit = YES;
    }
}

@end
